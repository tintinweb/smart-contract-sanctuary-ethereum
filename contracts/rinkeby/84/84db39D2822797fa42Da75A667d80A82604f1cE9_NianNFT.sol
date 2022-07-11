// SPDX-License-Identifier: MIT

// Amended by HashLips
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
pragma solidity ^0.8.0;
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol
pragma solidity ^0.8.0;
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
     // 转移一个nft
     // 编号未tokenId的nft从from转移到to
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
     // 给他人授权，owner将编号为tokenid的nft授权给approved
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
     // 给他人授权，owner将所有的nft授权给operator
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
     // 查询一个人持有的nft的数量
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
     // 查询指定编号的nft的所有者
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * - 如果to是一个合约，必须实现了接口IERC721Receiver
     *
     * Emits a {Transfer} event.
     */
     // 转移nft  safeTransferFrom会调用_checkOnERC721Received
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
     // 转移nft，尽量使用safeTransferFrom  transferFrom不会调用_checkERC721Received
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
     // 授权to使用tokenId的权限，当tokenId被转移给其他人后，会自动撤销授权。
     // 只能授权给一个人，不能授权给多个人，授权给0x00地址相当于撤销了所有授权
     // 授权给自己也相当于撤销了所有授权吧
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
     // 查询tokenId的授权情况，tokenId必须存在
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
     // 将持有的所有nft授权给operator
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
     // 查询owner是否将所有的nft授权给了operator
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
     // 也是安全转移nft，这里增加了参数data
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol
pragma solidity ^0.8.0;
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
     // 总供应量
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
     // 获取owner的第index个nft，返回该nft的tokenid
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
     // 获取所有nft中第index个nft，返回该nft的tokenid
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File: @openzeppelin/contracts/utils/introspection/ERC165.sol
pragma solidity ^0.8.0;
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
 // 这是ERC165合约
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
     // 该合约支持的接口类型
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
     // uint256类型的数据转换成string类型
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
     // uint256类型的数据转换成十六禁止的string类型
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

// File: @openzeppelin/contracts/utils/Address.sol



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
     // 检查地址是否是合约
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        // 合约初始化时，code sieze是0，初始化完毕后才能获取code size

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
     // 向recipient发送以太币
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
     // 就是call函数
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
     // 底层的call函数
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,      // 调用函数的同时发送以太币
        string memory errorMessage
    ) internal returns (bytes memory) {
        // 先检查以太币是否充足
        require(address(this).balance >= value, "Address: insufficient balance for call");
        // 检查目标地址是否是合约
        require(isContract(target), "Address: call to non-contract");

        // 发起函数调用
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
     // 静态调用，不能修改目标合约的storage
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
     // 静态调用，不能修改目标合约的storage
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
     // delegate call
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
     // delegate call
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
     // 检查函数调用的结果
    function verifyCallResult(
        bool success,       // 函数调用是否成功
        bytes memory returndata,    // 函数调用返回的数据
        string memory errorMessage  // 如果出错了，打印的错误信息
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;  // 如果函数调用成功，直接返回调用结果
        } else {
            // Look for revert reason and bubble it up if present
            // 如果本身定义了错误信息，就使用定义的错误信息；否则使用外面传入的错误信息。
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
 // 带有元数据的EIP-721协议
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
     // 获取NFT的名称
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
     // 获取NFT的符号
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
     // 获取NFT的URL
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
 // 支持safeTransfer的合约需要实现这个接口
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
     // 就一个函数， onERC721Received，当接收到一个nft时调用这个函数。
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Context.sol
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


// File: @openzeppelin/contracts/token/ERC721/ERC721.sol
pragma solidity ^0.8.0;
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
 // OpenZeppelin定义的nft是带有元数据的nft
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;   // nft的名称

    // Token symbol
    string private _symbol; // nft的符号

    // Mapping from token ID to owner address
    // tokenid到owner的映射，保存每个token的拥有者
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    // 记录每个用户拥有的token数量
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    // 记录每个token的approve信息，一个token只能approve给一个用户
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    // 应该是一个用户将自己所有的token全部approve给了另外一个用户
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
     // nft的构造函数，设置nft的名称和符号
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
     // 这里为什么要override两个呢
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||     // 这是一个ERC721协议
            interfaceId == type(IERC721Metadata).interfaceId || // 这是一个带元数据的ERC721协议
            super.supportsInterface(interfaceId);   // 调用父类中的supportsInterface函数
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
     // 返回一个用户拥有的nft的数量
    function balanceOf(address owner) public view virtual override returns (uint256) {
        // 不能是0地址
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
     // 获取一个nft的拥有者
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        // 获取nft的拥有者
        address owner = _owners[tokenId];
        // 这个nft还没有mint出来，还不属于任何用户
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
     // 获取nft的名称
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
     // 获取nft的符号
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
     // 获取一个nft的URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // 这个nft必须已经被mint出来了，必须存在
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // 这是nft的uri的基础链接，这里的_baseURI()带有斜杠
        string memory baseURI = _baseURI();
        // 拼接成这个nft的uri
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
     // 获取baseuri，估计子合约会重写这个函数。
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
     // nft授权，将tokenid授权给to
    function approve(address to, uint256 tokenId) public virtual override {
        // 获取nft的owner，这里为什么采用合约调用的形式呢??
        address owner = ERC721.ownerOf(tokenId);
        // owner不能是to，不能授权给nft的拥有者
        require(to != owner, "ERC721: approval to current owner");

        require(
            // 自己的nft，才能授权给其他人 || nft的拥有者已经给msg.sender授权了，授的是所有nft的权限，只授予单个nft的权限还不行
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        // 正式授权
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
     // 获取一个nft的授权信息
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        // 这个nft必须已经被mint出来了
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];    // 返回这个nft的授权信息
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
     // 将自己所有的nft授权给operator
    function setApprovalForAll(address operator, bool approved) public virtual override {
        //  不能自己授权给自己
        require(operator != _msgSender(), "ERC721: approve to caller");

        // 将自己所有的nft授权给operator
        _operatorApprovals[_msgSender()][operator] = approved;
        // 记录日志
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
     // 查询owner是否将所有的nft授权给了operator
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
     // 转移nft
    function transferFrom(
        address from,   // 从这个人
        address to,     // 转移给这个人
        uint256 tokenId // 这是转移的nft
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        // 必须有权限，或者就是自己的nft
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        // 转移nft
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
     // 这是safeTransferFrom函数
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
     // safeTransferFrom函数
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
     // 这是safeTransfer函数
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        // 先调用了transfer函数
        _transfer(from, to, tokenId);
        // safeTransfer会调用_checkOnERC721Received
        // 如果to是一个合约，必须实现了接口onERC721Received()
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
     // 判断一个nft是否存在
     // 如果拥有者是0x00地址，那么说明这个nft还不存在
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
     // 检查spender是否有权限操作tokenid指定的nft
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        // 这个nft必须已经mint出来了
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        // 获取这个nft的owner
        address owner = ERC721.ownerOf(tokenId);
        // 是自己的nft 或者 得到了授权
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
     // 这是safemin函数
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,    // 这里传入的是token id
        bytes memory _data
    ) internal virtual {
        // 先mint出nft
        _mint(to, tokenId);
        require(
            // 然后检查to合约是否实现了接口onERC721Received
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
     // 这是mint函数，将nft mint给to
    function _mint(address to, uint256 tokenId) internal virtual {
        // 不能mint给0地址
        require(to != address(0), "ERC721: mint to the zero address");
        // 这个nft必须还没有所有者
        require(!_exists(tokenId), "ERC721: token already minted");

        // 转移前，预先调用一个函数
        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1; // to多了一个nft
        _owners[tokenId] = to;  // 设置这个nft的所有者是to

        emit Transfer(address(0), to, tokenId); // 记录日志
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
     // 销毁一个nft
    function _burn(uint256 tokenId) internal virtual {
        // 或者这个nft的所有者
        address owner = ERC721.ownerOf(tokenId);

        // 转移前的操作函数
        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);  // 已经销毁了，需要取消授权

        _balances[owner] -= 1;  // 用户的nft数量减少1
        delete _owners[tokenId];    // 删除这个nft的拥有者信息

        emit Transfer(owner, address(0), tokenId);  // 记录日志
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
     // 这是transfer函数
    function _transfer(
        address from,   // nft从这个地址转出
        address to,     // nft转给这个人
        uint256 tokenId // 转移的是这个nft
    ) internal virtual {
        // 这个nft的所有者必须是from，因此要从from将nft转出
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        // 不能转给0地址，转给0地址需要调用burn函数
        require(to != address(0), "ERC721: transfer to the zero address");

        // 在转移前可以调用这个函数
        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        // 转移后需要取消所有的授权
        _approve(address(0), tokenId);

        _balances[from] -= 1;   // from少了一个token
        _balances[to] += 1;     // to多了一个token
        _owners[tokenId] = to;  // 设置nft的拥有者是to

        emit Transfer(from, to, tokenId);   // 记录日志
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
     // 将一个nft授权给to
    function _approve(address to, uint256 tokenId) internal virtual {
        // 将这个nft授权给to
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);    // 发送消息，记录日志
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
     // 转完nft以后，还需要调用这个函数
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        // 如果nft转给了一个合约，继续检查
        if (to.isContract()) {
            // 如果一个合约想接收nft，那么这个合约必须实现了onERC721Received函数，
            // 这里就调用到了外部合约  也就是说nft不能随便转给另外的合约
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
     // 子合约可以实现这个函数
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol



pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
 // 这是ERC721Enumerable合约
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;   // 所有的nft

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
     // ERC165合约
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
     // 查找用户第index个nft
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        // 不能超过用户nft的数量
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        // 取出这个nft的编号
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
     // nft的总量
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
     // 通过index获取nft的tokenid
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
     //  重新了 _beforTokenTransfer函数
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // 先调用父合约的_beforeTokenTransfer函数
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {   // mint函数
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {    // 从from转出
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {     // burn函数
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {    // 转给了to
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
     // 将一个token转给to
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
     // 新mint了一个nft
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
     // 从from转出了一个nft
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
     // 销毁了一个nft
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


// File: @openzeppelin/contracts/access/Ownable.sol
pragma solidity ^0.8.0;
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.7.0 <0.9.0;

// 这是最终的nft合约
contract NianNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  // mint一个nft要花费0.05个以太币
  uint256 public cost = 0.001 ether;
  // 最大供应量是10000个
  uint256 public maxSupply = 30;
  // 每次最多可以mint20个nft
  uint256 public maxMintAmount = 2;
  // 暂停mint
  bool public paused = false;
  // 开牌
  bool public revealed = false;
  string public notRevealedUri;

  constructor(
    string memory _name,    // 名称
    string memory _symbol,  // 符号
    string memory _initBaseURI, // 初始的url
    string memory _initNotRevealedUri   // 没泄漏的url
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);   // 设置真正的baseurl
    setNotRevealedURI(_initNotRevealedUri); // 设置虚假的baseurl
  }

  // internal
  // 返回baseurl
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  // mint一个nft
  function mint(uint256 _mintAmount) public payable {
    // 获取现在的nft总量
    uint256 supply = totalSupply();
    require(!paused);   // 必须没有暂停
    require(_mintAmount > 0);   // mint的数量必须大于0
    require(_mintAmount <= maxMintAmount);  // mint的数量必须不超过maxMintAmount
    require(supply + _mintAmount <= maxSupply); // mint后的总量不能超过最大供应量

    // 如果不是owner，那么还必须转以太币，才能mint，不能免费mint
    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    // 开始mint
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);    // supply+i是tokenId
    }
  }

  // 获取用户所有的tokenid列表
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    // 获取这个用户的nft的数量
    uint256 ownerTokenCount = balanceOf(_owner);
    // 创建这么个数组
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i); // 记录每一个nft的tokenid
    }
    return tokenIds;
  }

   // 获取token的url
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId), // 这个tokenid必须已经存在了
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    // 现在还没有开牌，返回加的url
    if(revealed == false) {
        return notRevealedUri;
    }

    // 获取者正的baseurl
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        // 拼接成真正的url
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  // 开牌
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  // 设置mint时的成本
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  // 设置单次mint的最大数量
  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  // 设置虚假的url
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  // 设置baseurl
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  // 设置base extension
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  // 可以暂停mint
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  // 因为mint nft时支付了以太币，所以这里要取出以太币
  function withdraw() public payable onlyOwner {
    // This will pay HashLips 5% of the initial sale.
    // You can remove this if you want, or keep it in to support HashLips and his channel.
    // =============================================================================
//    (bool hs, ) = payable(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D).call{value: address(this).balance * 5 / 100}("");
//    require(hs);
    // =============================================================================
    
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}