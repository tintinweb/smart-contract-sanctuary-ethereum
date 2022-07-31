/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: MIT

/**
          _____                    _____                    _____                    _____            _____                    _____          
         /\    \                  /\    \                  /\    \                  /\    \          /\    \                  /\    \         
        /::\    \                /::\____\                /::\    \                /::\____\        /::\    \                /::\    \        
       /::::\    \              /:::/    /                \:::\    \              /:::/    /       /::::\    \              /::::\    \       
      /::::::\    \            /:::/    /                  \:::\    \            /:::/    /       /::::::\    \            /::::::\    \      
     /:::/\:::\    \          /:::/    /                    \:::\    \          /:::/    /       /:::/\:::\    \          /:::/\:::\    \     
    /:::/  \:::\    \        /:::/    /                      \:::\    \        /:::/    /       /:::/  \:::\    \        /:::/__\:::\    \    
   /:::/    \:::\    \      /:::/    /                       /::::\    \      /:::/    /       /:::/    \:::\    \       \:::\   \:::\    \   
  /:::/    / \:::\    \    /:::/    /      _____    ____    /::::::\    \    /:::/    /       /:::/    / \:::\    \    ___\:::\   \:::\    \  
 /:::/    /   \:::\ ___\  /:::/____/      /\    \  /\   \  /:::/\:::\    \  /:::/    /       /:::/    /   \:::\ ___\  /\   \:::\   \:::\    \ 
/:::/____/  ___\:::|    ||:::|    /      /::\____\/::\   \/:::/  \:::\____\/:::/____/       /:::/____/     \:::|    |/::\   \:::\   \:::\____\
\:::\    \ /\  /:::|____||:::|____\     /:::/    /\:::\  /:::/    \::/    /\:::\    \       \:::\    \     /:::|____|\:::\   \:::\   \::/    /
 \:::\    /::\ \::/    /  \:::\    \   /:::/    /  \:::\/:::/    / \/____/  \:::\    \       \:::\    \   /:::/    /  \:::\   \:::\   \/____/ 
  \:::\   \:::\ \/____/    \:::\    \ /:::/    /    \::::::/    /            \:::\    \       \:::\    \ /:::/    /    \:::\   \:::\    \     
   \:::\   \:::\____\       \:::\    /:::/    /      \::::/____/              \:::\    \       \:::\    /:::/    /      \:::\   \:::\____\    
    \:::\  /:::/    /        \:::\__/:::/    /        \:::\    \               \:::\    \       \:::\  /:::/    /        \:::\  /:::/    /    
     \:::\/:::/    /          \::::::::/    /          \:::\    \               \:::\    \       \:::\/:::/    /          \:::\/:::/    /     
      \::::::/    /            \::::::/    /            \:::\    \               \:::\    \       \::::::/    /            \::::::/    /      
       \::::/    /              \::::/    /              \:::\____\               \:::\____\       \::::/    /              \::::/    /       
        \::/____/                \::/____/                \::/    /                \::/    /        \::/____/                \::/    /        
                                  ~~                       \/____/                  \/____/          ~~                       \/____/         
                                                                                                                                              
**/

pragma solidity >=0.4.24 <0.9.0;

/**
 * @title Initializable
 *
 * @dev Deprecated. This contract is kept in the Upgrades Plugins for backwards compatibility purposes.
 * Users should use openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol instead.
 *
 * Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

pragma solidity ^0.8.7;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

pragma solidity ^0.8.7;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context, Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    // constructor() {
    //     _transferOwnership(_msgSender());
    // }

    // function initialize() public virtual initializer {
    //     _transferOwnership(_msgSender());
    // }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

pragma solidity ^0.8.7;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    // function functionDelegateCall(address target, bytes memory data)
    //     internal
    //     returns (bytes memory)
    // {
    //     return
    //         functionDelegateCall(
    //             target,
    //             data,
    //             "Address: low-level delegate call failed"
    //         );
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    //  * but performing a delegate call.
    //  *
    //  * _Available since v3.4._
    //  */
    // function functionDelegateCall(
    //     address target,
    //     bytes memory data,
    //     string memory errorMessage
    // ) internal returns (bytes memory) {
    //     require(isContract(target), "Address: delegate call to non-contract");

    //     (bool success, bytes memory returndata) = target.delegatecall(data);
    //     return verifyCallResult(success, returndata, errorMessage);
    // }

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol

pragma solidity ^0.8.7;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol

pragma solidity ^0.8.7;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol

pragma solidity ^0.8.7;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol

pragma solidity ^0.8.7;

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

pragma solidity ^0.8.7;

contract AccessControl is Ownable {
    event GrantRole(
        bytes32 indexed role,
        address indexed account,
        uint256 indexed id
    );
    event RevokeRole(
        bytes32 indexed role,
        address indexed account,
        uint256 indexed id
    );

    mapping(bytes32 => mapping(address => mapping(uint256 => bool)))
        public roles;

    // 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 public constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    // 0x58c8e11deab7910e89bf18a1168c6e6ef28748f00fd3094549459f01cec5e0aa
    bytes32 public constant MODERATOR =
        keccak256(abi.encodePacked("MODERATOR"));

    modifier onlyRole(bytes32 _role, uint256 _id) {
        require(roles[_role][msg.sender][_id], "Not authorized");
        _;
    }

    function _grantRole(
        bytes32 _role,
        address _account,
        uint256 _id
    ) internal {
        roles[_role][_account][_id] = true;
        emit GrantRole(_role, _account, _id);
    }

    function _revokeRole(
        bytes32 _role,
        address _account,
        uint256 _id
    ) internal {
        roles[_role][_account][_id] = false;
        emit RevokeRole(_role, _account, _id);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol

pragma solidity ^0.8.7;

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is
    Context,
    ERC165,
    IERC1155,
    IERC1155MetadataURI,
    AccessControl
{
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    // string private _uri;

    mapping(uint256 => string) private _uri;

    /**
     * @dev See {_setURI}.
     */

    // constructor(string memory uri_) {
    //     _setURI(uri_);
    // }

    // constructor() {
    // }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
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
    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _uri[_id];
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
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
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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

    // function indexOf(uint256[] memory arr, uint256 searchFor) private returns (uint256) {
    // for (uint256 i = 0; i < arr.length; i++) {
    // if (arr[i] == searchFor) {
    // return i;
    //     }
    // }
    // }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
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
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
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
    function _setURI(string memory newuri, uint256 _id) internal virtual {
        _uri[_id] = newuri;
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

        _beforeTokenTransfer(
            operator,
            address(0),
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
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
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
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

        // address operator = from;

        _beforeTokenTransfer(
            operator,
            from,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

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
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
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
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
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
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
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

pragma solidity ^0.8.7;

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;
    uint256 private _totalSpots;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function totalSpots() public view virtual returns (uint256) {
        return _totalSpots;
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    function indexOfAddress(address[] memory arr, address searchFor)
        public
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return i;
            }
        }
        revert("Address Not Found");
    }

    function indexOfUint256(uint256[] memory arr, uint256 searchFor)
        public
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return i;
            }
        }
        revert("Uint Not Found");
    }

    function addressNotIndexed(address[] memory arr, address searchFor)
        public
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                revert("Address Found");
            }
        }
        return 1;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // MINT
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
                _totalSpots += amounts[i];
            }
        }
        // BURN
        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
                _totalSpots -= amounts[i];
            }
        }
    }
}

abstract contract UseStrings {
    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function validateString(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length > 30 || b[0] == 0x20 || b[b.length - 1] == 0x20)
            return false;
        return true;
    }

    function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

pragma solidity ^0.8.7;

contract Guilds is ERC1155Supply, UseStrings {
    string public name;
    string public symbol;
    uint256 private _lastModId;
    uint256 private _totalGuilds;
    uint256 private _lastTicket;
    address private deployerOne;
    address private deployerTwo;
    uint256 public minimumMintRate;

    struct Guild {
        uint256 TokenId;
        string GuildName;
        string GuildDesc;
        address Admin;
        address[] GuildMembers;
        address[] GuildMods;
        string GuildType;
        uint256[] Appeals;
        uint256 UnlockDate;
        uint256 LockDate;
        string GuildRules;
        bool FreezeMetaData;
        address[] Kicked;
    }

    struct CourtOfAppeals {
        uint256 id;
        uint256 TokenId;
        address Kicked;
        string Message;
        uint256 For;
        uint256 Against;
        uint256 TimeStamp;
        address[] Voters;
    }

    mapping(uint256 => Guild) AllGuilds;
    mapping(uint256 => CourtOfAppeals) CourtTickets;
    mapping(address => uint256[]) MemberTickets;
    mapping(address => uint256[]) private KickedFrom;
    mapping(address => uint256[]) private GuildsByAddress;
    mapping(string => uint256) private GuildByName;
    mapping(uint256 => address) public ModAddressById;
    mapping(uint256 => mapping(address => uint256)) public ModMintLimit;
    mapping(uint256 => address) public tokenAdmin;

    function initialize() public virtual initializer {
        _transferOwnership(_msgSender());
        name = "Guilds";
        symbol = "GUILDS";
        _lastModId = 1526;
        _lastTicket = 9048;
        deployerOne = 0x76e763f6Ff933fDFBAe0a51DDc9740B47048CcDA;
        deployerTwo = 0xd04FCf03971aC82fC9eAacB2BBdc863479ea134b;
        minimumMintRate = 0;
    }

    // PUBLIC READ FUNCTIONS:

    function totalGuilds() public view virtual returns (uint256) {
        return _totalGuilds;
    }

    function lastModId() public view virtual returns (uint256) {
        return _lastModId;
    }

    function getGuildsByMember(address _address)
        public
        view
        returns (uint256[] memory)
    {
        return GuildsByAddress[_address];
    }

    function getMemberTickets(address _address)
        public
        view
        returns (uint256[] memory)
    {
        return MemberTickets[_address];
    }

    function getKickedByMember(address _address)
        public
        view
        returns (uint256[] memory)
    {
        return KickedFrom[_address];
    }

    function getGuildByName(string memory _name) public view returns (uint256) {
        return GuildByName[_name];
    }

    function getIndexOfMember(uint256 _id, address _account)
        public
        view
        returns (uint256)
    {
        return indexOfAddress(AllGuilds[_id].GuildMembers, _account);
    }

    function getAppealByTicket(uint256 _ticket, uint256 _tokenId)
        public
        view
        returns (CourtOfAppeals memory)
    {
        require(
            indexOfAddress(AllGuilds[_tokenId].GuildMembers, msg.sender) >= 0 ||
                indexOfAddress(AllGuilds[_tokenId].GuildMods, msg.sender) >= 0,
            "Only guild members can display appeals"
        );
        return CourtTickets[_ticket];
    }

    function getGuildById(uint256 _id) public view returns (Guild memory) {
        return AllGuilds[_id];
    }

    // GUILD MASTER FUNCTIONS:

    function removeAppealFromCourt(uint256 _ticketId, uint256 _tokenId)
        public
        onlyRole(ADMIN, _tokenId)
    {
        require(
            block.timestamp >= (CourtTickets[_ticketId].TimeStamp + 7 days),
            "Can remove appeal only after 7 days"
        );

        delete CourtTickets[_ticketId];
    }

    function removeMemberFromBlacklist(address _address, uint256 _tokenId)
        public
        onlyRole(ADMIN, _tokenId)
    {
        removeItemFromAddressArray(
            AllGuilds[_tokenId].Kicked,
            indexOfAddress(AllGuilds[_tokenId].Kicked, _address)
        );
        removeItemFromUintArray(
            KickedFrom[_address],
            indexOfUint256(KickedFrom[_address], _tokenId)
        );
    }

    function lockSpots(
        uint256 _tokenId,
        uint256 _unlockDate,
        uint256 _lockDate
    ) public onlyRole(ADMIN, _tokenId) {
        require(_lockDate >= block.timestamp, "Can't lock the past");
        require(
            AllGuilds[_tokenId].UnlockDate <= block.timestamp,
            "Guild spots are already locked"
        );
        AllGuilds[_tokenId].UnlockDate = _unlockDate;
        AllGuilds[_tokenId].LockDate = _lockDate;
    }

    function freezeMetaData(uint256 _tokenId) public onlyRole(ADMIN, _tokenId) {
        AllGuilds[_tokenId].FreezeMetaData = true;
    }

    function setGuildRules(string memory _rules, uint256 _tokenId)
        public
        onlyRole(ADMIN, _tokenId)
    {
        AllGuilds[_tokenId].GuildRules = _rules;
    }

    function adminMint(uint256 _amount, uint256 _id)
        public
        payable
        onlyRole(ADMIN, _id)
    {
        require(
            block.timestamp >= (AllGuilds[_id].UnlockDate) ||
                block.timestamp <= (AllGuilds[_id].LockDate),
            "Guild spots are locked"
        );
        uint256 ownerFee = _amount * minimumMintRate;
        require(msg.value >= ownerFee, "Not enough ethers sent");
        _mint(tokenAdmin[_id], _id, _amount, "");
    }

    function assignModerator(
        address _account,
        uint256 _id,
        uint256 _mintLimit
    ) public onlyRole(ADMIN, _id) {
        require(
            indexOfAddress(AllGuilds[_id].GuildMembers, _account) >= 0,
            "Not a member"
        );
        _lastModId += 1;
        _grantRole(MODERATOR, _account, _id);
        ModAddressById[_lastModId] = _account;
        ModMintLimit[_id][_account] = _mintLimit;
        AllGuilds[_id].GuildMods.push(_account);
        removeItemFromAddressArray(
            AllGuilds[_id].GuildMembers,
            indexOfAddress(AllGuilds[_id].GuildMembers, _account)
        );
    }

    function bulkAssignModerators(
        address[] memory _addresses,
        uint256 _id,
        uint256 _limit
    ) public onlyRole(ADMIN, _id) {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            assignModerator(_addresses[i], _id, _limit);
        }
    }

    function adminSetModMintLimit(
        uint256 _id,
        address _account,
        uint256 _mintLimit
    ) public onlyRole(ADMIN, _id) {
        _setModMintLimit(_id, _account, _mintLimit);
    }

    function revokeRole(
        bytes32 _role,
        address _account,
        uint256 _id
    ) public onlyRole(ADMIN, _id) {
        uint256 _modIndexInGuild = indexOfAddress(
            AllGuilds[_id].GuildMods,
            _account
        );
        if (_role == MODERATOR) {
            removeItemFromAddressArray(
                AllGuilds[_id].GuildMods,
                _modIndexInGuild
            );
            ModMintLimit[_id][_account] = 0;
            // new member
            addMemberToGuild(_account, _id);
            addGuildToMember(_account, _id);
        }
        _revokeRole(_role, _account, _id);
    }

    function burn(
        uint256 _id,
        uint256 _amount,
        address _address
    ) public onlyRole(ADMIN, _id) {
        require(
            compareStrings(AllGuilds[_id].GuildType, "democracy") ||
                compareStrings(AllGuilds[_id].GuildType, "monarchy"),
            "Cannot kick from meritocracy guild"
        );
        _burn(_address, _id, _amount);
        AllGuilds[_id].Kicked.push(_address);
        addGuildToKickedFrom(_address, _id);
    }

    function editMetadata(
        string memory _name,
        string memory _desc,
        string memory _uri,
        uint256 _id
    ) public onlyRole(ADMIN, _id) {
        // If name is not being changed:
        if (getGuildByName(lower(_name)) != _id) {
            require(getGuildByName(lower(_name)) == 0, "Name already exists");
        } else {
            // Update guild name:
            string memory oldName = AllGuilds[_id].GuildName;
            GuildByName[lower(oldName)] = 0;
            GuildByName[lower(_name)] = _id;
        }

        require(
            validateString(_name),
            "Guild name must not contain spaces on side"
        );
        AllGuilds[_id].GuildName = _name;
        AllGuilds[_id].GuildDesc = _desc;
        setNewTokenUri(_id, _uri);
    }

    function setNewTokenUri(uint256 _id, string memory _newUri)
        public
        onlyRole(ADMIN, _id)
    {
        require(!AllGuilds[_id].FreezeMetaData, "Guild metadata is frozen");
        _setURI(_newUri, _id);
        emit URI(_newUri, _id);
    }

    // MODERATOR FUNCTIONS:

    function modMint(uint256 _amount, uint256 _id)
        public
        payable
        onlyRole(MODERATOR, _id)
    {
        require(
            block.timestamp >= (AllGuilds[_id].UnlockDate) ||
                block.timestamp <= (AllGuilds[_id].LockDate),
            "Guild spots are locked"
        );
        uint256 ownerFee = _amount * minimumMintRate;
        uint256 _modMintLimit = ModMintLimit[_id][msg.sender];
        require(_modMintLimit >= _amount, "Cant mint specified amount");
        require(msg.value >= ownerFee, "Not enough ethers sent");
        _setModMintLimit(_id, msg.sender, (_modMintLimit - _amount));
        _mint(msg.sender, _id, _amount, "");
    }

    // PUBLIC WRITE:

    function appealToCourt(uint256 _tokenId, string memory _message) public {
        uint256[] memory senderKickedFrom = KickedFrom[msg.sender];
        require(
            indexOfUint256(senderKickedFrom, _tokenId) >= 0,
            "Cant appeal for the specified guild"
        );
        require(
            compareStrings(AllGuilds[_tokenId].GuildType, "democracy"),
            "Guild governance is monarchy"
        );
        _lastTicket += 1;
        MemberTickets[msg.sender].push(_lastTicket);
        AllGuilds[_tokenId].Appeals.push(_lastTicket);
        CourtTickets[_lastTicket].id = _lastTicket;
        CourtTickets[_lastTicket].TokenId = _tokenId;
        CourtTickets[_lastTicket].Kicked = msg.sender;
        CourtTickets[_lastTicket].Message = _message;
        CourtTickets[_lastTicket].For = 0;
        CourtTickets[_lastTicket].Against = 0;
        CourtTickets[_lastTicket].TimeStamp = block.timestamp;
        CourtTickets[_lastTicket].Voters;
    }

    function voteForAppeal(uint256 _ticketId, uint256 _value) public {
        uint256 ticketGuild = CourtTickets[_ticketId].TokenId;
        require(
            msg.sender != AllGuilds[ticketGuild].Admin,
            "Guild master cannot vote for appeal"
        );
        require(
            indexOfAddress(AllGuilds[ticketGuild].GuildMembers, msg.sender) >=
                0 ||
                indexOfAddress(AllGuilds[ticketGuild].GuildMods, msg.sender) >=
                0,
            "Only guild members can vote"
        );
        require(
            addressNotIndexed(CourtTickets[_ticketId].Voters, msg.sender) >= 0,
            "Cannot vote for the same ticket more than one time"
        );
        if (_value == 0) {
            CourtTickets[_ticketId].For += 1;
        } else if (_value == 1) {
            CourtTickets[_ticketId].Against += 1;
        } else {
            revert("Can vote only for or againt");
        }
        CourtTickets[_ticketId].Voters.push(msg.sender);
    }

    function createNewGuild(
        uint256 _amount,
        string memory _uri,
        string memory _name,
        string memory _desc,
        string memory _guildType
    ) public payable {
        require(
            msg.value >= (_amount * minimumMintRate),
            "Not enough ethers sent"
        );
        uint256 _id = totalGuilds() + 1;
        _totalGuilds = _id;
        _grantAdminRole(ADMIN, msg.sender, _id);
        setNewGuild(_id, msg.sender, _name, _desc, _guildType);
        tokenAdmin[_id] = msg.sender;
        _mint(msg.sender, _id, _amount, "");
        setTokenUri(_id, _uri);
    }

    function bulkSendSpots(
        address[] memory _addresses,
        uint256 _id,
        uint256 _amount
    ) public {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            _safeTransferFrom(msg.sender, _addresses[i], _id, _amount, "0x0");
        }
    }

    // PRIVATE WRITE:

    function removeItemFromAddressArray(
        address[] storage _addresses,
        uint256 index
    ) private {
        address[] storage AddArr = _addresses;
        AddArr[index] = AddArr[AddArr.length - 1];
        AddArr.pop();
    }

    function removeItemFromUintArray(uint256[] storage _uints, uint256 index)
        private
    {
        uint256[] storage UintsArr = _uints;
        UintsArr[index] = UintsArr[UintsArr.length - 1];
        UintsArr.pop();
    }

    function setNewGuild(
        uint256 _id,
        address _initiator,
        string memory _name,
        string memory _desc,
        string memory _guildType
    ) private {
        require(
            compareStrings(_guildType, "democracy") ||
                compareStrings(_guildType, "monarchy") ||
                compareStrings(_guildType, "meritocracy"),
            "Unrecognized guild type"
        );
        require(
            validateString(_name),
            "Guild name must not contain spaces on sides"
        );

        string memory clearGuildName = lower(_name);
        require(getGuildByName(clearGuildName) == 0, "Name already exists");
        AllGuilds[_id].TokenId = _id;
        AllGuilds[_id].GuildName = _name;
        AllGuilds[_id].GuildDesc = _desc;
        AllGuilds[_id].GuildMembers;
        AllGuilds[_id].Admin = _initiator;
        AllGuilds[_id].GuildMods;
        AllGuilds[_id].GuildType = _guildType;
        AllGuilds[_id].GuildRules;
        AllGuilds[_id].FreezeMetaData = false;
        AllGuilds[_id].Kicked;
        AllGuilds[_id].LockDate = block.timestamp;
        AllGuilds[_id].UnlockDate = block.timestamp;
        GuildByName[clearGuildName] = _id;
    }

    function _setModMintLimit(
        uint256 _id,
        address _account,
        uint256 _mintLimit
    ) private {
        ModMintLimit[_id][_account] = _mintLimit;
    }

    function setTokenUri(uint256 _id, string memory _uri) private {
        require(exists(_id), "Token is not exists");
        _setURI(_uri, _id);
        emit URI(_uri, _id);
    }

    function addMemberToGuild(address _address, uint256 _id) private {
        AllGuilds[_id].GuildMembers.push(_address);
    }

    function addGuildToMember(address _address, uint256 _id) private {
        GuildsByAddress[_address].push(_id);
    }

    function addGuildToKickedFrom(address _address, uint256 _id) private {
        KickedFrom[_address].push(_id);
    }

    function _grantAdminRole(
        bytes32 _role,
        address _account,
        uint256 _id
    ) private {
        _grantRole(_role, _account, _id);
    }

    // Owners:

    function setMinimumMintRate(uint256 _mintRate) external onlyOwner {
        minimumMintRate = _mintRate;
    }

    function withdraw() public {
        require(
            msg.sender == deployerOne || msg.sender == deployerTwo,
            "Sender is not deployer"
        );
        uint256 balance1 = address(this).balance / 2;
        uint256 balance2 = address(this).balance / 2;
        payable(deployerOne).transfer(balance1);
        payable(deployerTwo).transfer(balance2);
    }

    // Hooks:

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            if (address(0) != from) {
                // remove the sender if no tokens left and revoke roles:
                uint256 _tokensLeft = balanceOf(from, ids[i]);
                // Kick:
                if (_tokensLeft == amounts[i]) {
                    // If MOD:
                    if (
                        roles[
                            0x58c8e11deab7910e89bf18a1168c6e6ef28748f00fd3094549459f01cec5e0aa
                        ][from][ids[i]]
                    ) {
                        _revokeRole(MODERATOR, from, ids[i]);
                        removeItemFromAddressArray(
                            AllGuilds[ids[i]].GuildMods,
                            indexOfAddress(AllGuilds[ids[i]].GuildMods, from)
                        );
                    } else if (tokenAdmin[ids[i]] == from && address(0) != to) {
                        // If is admin:
                        _revokeRole(ADMIN, from, ids[i]);
                        tokenAdmin[ids[i]] = to;
                        AllGuilds[ids[i]].Admin = to;
                        _grantAdminRole(ADMIN, to, ids[i]);
                    } else {
                        // remove member from guild
                        removeItemFromAddressArray(
                            AllGuilds[ids[i]].GuildMembers,
                            indexOfAddress(AllGuilds[ids[i]].GuildMembers, from)
                        );
                    }
                    // remove guild from member
                    removeItemFromUintArray(
                        GuildsByAddress[from],
                        indexOfUint256(GuildsByAddress[from], ids[i])
                    );
                }
            }

            if (address(0) != to) {
                // If guild exists:
                if (exists(ids[i])) {
                    // Add new member:
                    if (balanceOf(to, ids[i]) == 0) {
                        // new member
                        if (to != tokenAdmin[ids[i]]) {
                            addMemberToGuild(to, ids[i]);
                        }
                        addGuildToMember(to, ids[i]);
                    }
                }
            }
        }
    }
}