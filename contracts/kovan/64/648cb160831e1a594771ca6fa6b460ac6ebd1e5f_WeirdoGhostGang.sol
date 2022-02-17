/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// File: @elsess/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 * @dev 与地址类型相关的函数集合
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
     
     * @dev 如果 `account` 是合约，则返回 true。
     *
     * [重要的]
     * ====
     * 假设这个函数返回的地址是不安全的
     * false 是外部拥有的帐户 (EOA)，而不是合同。
     *
     * 其中，`isContract` 将在以下情况下返回 false
     *地址类型：
     *
     * - 外部拥有的帐户
     * - 建筑合同
     * - 将创建合约的地址
     * - 合约所在的地址，但已被销毁
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // 这个方法依赖于 extcodesize，它在合约中返回 0
        // 构造，因为代码只存储在末尾
        // 构造函数执行。
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
     * @dev 替换 Solidity 的 `transfer`：将 `amount` wei 发送到
     * `recipient`，转发所有可用的 gas 并在错误时恢复。
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] 增加gas费用
     * 某些操作码，可能使合约超过 2300 gas 限制
     * 由 `transfer` 强加，使他们无法通过以下方式接收资金
     *`转移`。 {sendValue} 消除了这个限制。
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[了解更多]。
     *
     * 重要提示：因为控制权转移到了`recipient`，所以必须小心
     * 不会造成重入漏洞。考虑使用
     * {ReentrancyGuard} 或
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions 模式]。
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
     
     * @dev 使用低级 `call` 执行 Solidity 函数调用。一个
     * 普通的 `call` 是函数调用的不安全替代品：使用这个
     * 代替函数。
     *
     * 如果`target`由于revert原因而revert，它会被这个冒泡
     * 函数（如常规的 Solidity 函数调用）。
     *
     * 返回原始返回数据。要转换为预期的返回值，
     * 使用 https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`]。
     *
     * 要求：
     *
     * - `target` 必须是合约。
     * - 用 `data` 调用 `target` 不能恢复。
     *
     * _自 v3.1 起可用。_
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     * @dev 与 {xref-Address-functionCall-address-bytes-}[`functionCall`] 相同，但使用
     * `errorMessage` 作为`target` 恢复时的后备恢复原因。
     *
     * _自 v3.1 起可用。_
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
     
     * @dev 与 {xref-Address-functionCall-address-bytes-}[`functionCall`] 相同，
     * 但也将 `value` wei 转移到 `target`。
     *
     * 要求：
     *
     * - 调用合约的 ETH 余额必须至少为 `value`。
     * - 调用的 Solidity 函数必须是 `payable`。
     *
     * _自 v3.1 起可用。_
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
     * @dev 与 {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`] 相同，但是
     * 当 `t​​arget` 恢复时，将 `errorMessage` 作为后备恢复原因。
     *
     * _自 v3.1 起可用。_
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
     
     * @dev 与 {xref-Address-functionCall-address-bytes-}[`functionCall`] 相同，
     * 但执行静态调用。
     *
     * _自 v3.3 起可用。_
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * @dev 与 {xref-Address-functionCall-address-bytes-string-}[`functionCall`] 相同，
     * 但执行静态调用。
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
     * @dev 与 {xref-Address-functionCall-address-bytes-}[`functionCall`] 相同，
     * 但执行委托调用
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     * @dev 与 {xref-Address-functionCall-address-bytes-string-}[`functionCall`] 相同，
     * 但执行委托调用
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
     *@dev 工具来验证低级别调用是否成功，如果没有成功则恢复，或者通过冒泡
     * 使用提供的原因恢复原因。
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
            // 查找还原原因并在存在时将其冒泡
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                // 冒泡还原原因的最简单方法是通过程序集使用内存
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
// File: @elsess/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 
 * @title ERC721 令牌接收器接口
 * @dev 任何想要支持 safeTransfers 的合约的接口
 * 来自 ERC721 资产合约。
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
     
     * @dev 每当 {IERC721} `tokenId` 代币通过 {IERC721-safeTransferFrom} 转移到此合约时
     * 由 `from` 中的 `operator` 调用，该函数被调用。
     *
     * 它必须返回其 Solidity 选择器以确认代币转移。
     * 如果返回任何其他值或接收方未实现该接口，则转账将被还原。
     *
     * 选择器可以在 Solidity 中通过 `IERC721.onERC721Received.selector` 获得。
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: @elsess/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 * @dev ERC165 标准的接口，定义在
 * https://eips.ethereum.org/EIPS/eip-165[EIP]。
 *
 * 实现者可以声明对合约接口的支持，然后可以
 * 被其他人查询（{ERC165Checker}）。
 *
 * 有关实现，请参阅 {ERC165}。
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     
     * @dev 如果此合约实现了定义的接口，则返回 true
     * `interfaceId`。见对应
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP部分]
     * 了解有关如何创建这些 ID 的更多信息。
     *
     * 此函数调用必须使用少于 30 000 个gas。
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: @elsess/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
 
 * @dev 实现 {IERC165} 接口。
 *
 * 想要实现 ERC165 的合约应该从这个合约继承并覆盖 {supportsInterface} 来检查
 * 用于将支持的附加接口 ID。例如：
 *
 * ```坚固性
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 * return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 *```
 *
 * 或者，{ERC165Storage} 提供了一种更易于使用但更昂贵的实现方式。
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
// File: @elsess/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 * @dev 符合 ERC721 的合约的必需接口。
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * @dev 当 `t​​okenId` 令牌从 `from` 转移到 `to` 时发出。
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     * @dev 当 `owner` 启用 `approved` 来管理 `tokenId` 令牌时发出。
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     * @dev 当 `owner` 启用或禁用（`approved`）`operator` 以管理其所有资产时发出。
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     * @dev 返回“所有者”账户中的代币数量。
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     
     * @dev 返回 `tokenId` 令牌的所有者。
     *
     * 要求：
     *
     * - `tokenId` 必须存在。
     */
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
     *
     * Emits a {Transfer} event.
     * @dev 安全地将 `tokenId` 令牌从 `from` 转移到 `to`，首先检查合约接收者
     * 了解 ERC721 协议以防止令牌被永久锁定。
     *
     * 要求：
     *
     * - `from` 不能是零地址。
     * - `to` 不能是零地址。
     * - `tokenId` 令牌必须存在并归 `from` 所有。
     * - 如果调用者不是 `from`，则必须已通过 {approve} 或 {setApprovalForAll} 允许移动此令牌。
     * - 如果 `to` 指的是智能合约，它必须实现 {IERC721Receiver-onERC721Received}，这是在安全传输时调用的。
     *
     * 发出 {Transfer} 事件。
     */
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
     * @dev 将 `tokenId` 令牌从 `from` 转移到 `to`。
     *
     * 警告：不鼓励使用此方法，尽可能使用 {safeTransferFrom}。
     *
     * 要求：
     *
     * - `from` 不能是零地址。
     * - `to` 不能是零地址。
     * - `tokenId` 令牌必须由 `from` 拥有。
     * - 如果调用者不是 `from`，则必须通过 {approve} 或 {setApprovalForAll} 批准移动此令牌。
     *
     * 发出 {Transfer} 事件。
     */
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
     * @dev 允许 `to` 将 `tokenId` 令牌转移到另一个帐户。
     * 转账token时清除审批。
     *
     * 一次只能批准一个账户，所以批准零地址会清除之前的批准。
     *
     * 要求：
     *
     * - 调用者必须拥有令牌或者是经过批准的操作员。
     * - `tokenId` 必须存在。
     *
     * 发出 {Approval} 事件。
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     
     * @dev 返回为 `tokenId` 令牌批准的帐户。
     *
     * 要求：
     *
     * - `tokenId` 必须存在。
     */
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
     * @dev 批准或删除 `operator` 作为调用者的操作符。
     * 操作员可以为调用者拥有的任何令牌调用 {transferFrom} 或 {safeTransferFrom}。
     *
     * 要求：
     *
     * - `operator` 不能是调用者。
     *
     * 发出 {ApprovalForAll} 事件。
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     
     * @dev 返回是否允许 `operator` 管理 `owner` 的所有资产。
     *
     * 见 {setApprovalForAll}
     */
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
     
     * @dev 安全地将 `tokenId` 令牌从 `from` 转移到 `to`。
     *
     * 要求：
     *
     * - `from` 不能是零地址。
     * - `to` 不能是零地址。
     * - `tokenId` 令牌必须存在并归 `from` 所有。
     * - 如果调用者不是 `from`，则必须通过 {approve} 或 {setApprovalForAll} 批准移动此令牌。
     * - 如果 `to` 指的是智能合约，它必须实现 {IERC721Receiver-onERC721Received}，这是在安全传输时调用的。
     *
     * 发出 {Transfer} 事件。
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// File: @elsess/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @title ERC-721 Non-Fungible Token Standard，可选枚举扩展
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * @dev 返回合约存储的代币总量。
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     
     * @dev 返回由 `owner` 在其令牌列表的给定 `index` 处拥有的令牌 ID。
     * 与 {balanceOf} 一起使用来枚举所有 ``owner`` 的令牌。
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     * @dev 返回合约存储的所有代币的给定“索引”处的代币 ID。
     * 与 {totalSupply} 一起使用以枚举所有令牌。
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}
// File: @elsess/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @title ERC-721 Non-Fungible Token Standard，可选的元数据扩展
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     * @dev 返回令牌集合名称。
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     * @dev 返回令牌集合符号。
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @dev 返回 `tokenId` 令牌的统一资源标识符 (URI)。
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: @elsess/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     * @dev 将 `uint256` 转换为其 ASCII `string` 十进制表示。
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
     * @dev 将 `uint256` 转换为其 ASCII `string` 十六进制表示。
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
     * @dev 将 `uint256` 转换为其 ASCII `string` 具有固定长度的十六进制表示。
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
// File: @elsess/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 * @dev 椭圆曲线数字签名算法 (ECDSA) 操作。
 *
 * 这些功能可用于验证消息是否由持有者签名
 * 给定地址的私钥
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * @dev 返回签名散列消息（`hash`）的地址
     * `signature` 或错误字符串。该地址随后可用于验证目的。
     *
     * `ecrecover` EVM 操作码允许可延展（非唯一）签名：
     *此函数通过要求`s`值在较低的值来拒绝它们
     * 半阶，并且 `v` 值为 27 或 28。
     *
     * 重要提示：`hash` _must_ 是哈希运算的结果
     *验证是安全的：可以制作签名
     * 恢复到非散列数据的任意地址。一种确保安全的方法
     * 这是通过接收原始消息的哈希值（否则可能
     * 太长），然后调用 {toEthSignedMessageHash} 就可以了。

     * Documentation for signature generation:
     * 签名生成文档：
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        //检查签名长度
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // ecrecover 接受签名参数，并且是获取它们的唯一方法
            // currently is to use assembly.
            // 目前是使用汇编。
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // ecrecover 接受签名参数，并且是获取它们的唯一方法
            // currently is to use assembly.
            // 目前是使用汇编。
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     * @dev 返回签名散列消息（`hash`）的地址
     *`签名`。该地址随后可用于验证目的。
     *
     * `ecrecover` EVM 操作码允许可延展（非唯一）签名：
     * 此函数通过要求`s`值在较低的值来拒绝它们
     * 半阶，并且 `v` 值为 27 或 28。
     *
     * 重要提示：`hash` _must_ 是哈希运算的结果
     * 验证是安全的：可以制作签名
     * 恢复到非散列数据的任意地址。一种确保安全的方法
     * 这是通过接收原始消息的哈希值（否则可能
     * 太长），然后调用 {toEthSignedMessageHash} 就可以了。
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     * @dev {ECDSA-tryRecover} 的重载，分别接收 `r` 和 `vs` 短签名字段。
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     * @dev {ECDSA-recover} 的重载，分别接收 `r 和 `vs` 短签名字段。
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.

     * @dev 接收 `v` 的 {ECDSA-tryRecover} 重载，
     * `r` 和 `s` 签名字段分开。
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // EIP-2 仍然允许 ecrecover() 的签名延展性。消除这种可能性并进行签名
        // 独特的。以太坊黄皮书（https://ethereum.github.io/yellowpaper/paper.pdf）中的附录 F，定义
        // (301) 中 s 的有效范围：0 < s < secp256k1n ÷ 2 + 1，对于 (302) 中的 v：v ∈ {27, 28}。最多
        // 来自当前库的签名生成一个唯一的签名，其 s 值按下半部分顺序排列。

        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        
        // 如果你的库生成了可延展的签名，比如s-values在上限范围内，计算一个新的s-value
        // 使用 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 并将 v 从 27 翻转到 28 或
        // 反之亦然。如果您的库还为 v 生成 0/1 而不是 27/28 的签名，请将 27 添加到 v 以接受
        // 这些可延展的签名也是如此。
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        // 如果签名有效（且不可延展），则返回签名者地址
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     * @dev 接收 `v` 的 {ECDSA-recover} 重载，
     * `r` 和 `s` 签名字段分开。
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     
     * @dev 返回一个以太坊签名消息，由“哈希”创建。这
     * 产生对应于用
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC 方法作为 EIP-191 的一部分。
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        
        // 32 是哈希的字节长度，
        // 由上面的类型签名强制执行
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     * @dev 返回从 `s` 创建的以太坊签名消息。这
     * 产生对应于用
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC 方法作为 EIP-191 的一部分
     * 见{恢复}。
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
        
     * @dev 返回一个以太坊签名的类型数据，创建自
     * `domainSeparator` 和 `structHash`。这会产生对应的哈希
     * 与签署的那一份
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC 方法作为 EIP-712 的一部分。
     *
     * 见 {恢复}。
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
// File: @elsess/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 
 * @dev 合约模块，有助于防止对函数的重入调用。
 *
 * 从 `ReentrancyGuard` 继承将使 {nonReentrant} 修饰符
 * 可用，可应用于函数以确保没有嵌套
 *（可重入）调用它们。
 *
 * 请注意，因为有一个 `nonReentrant` 守卫，函数标记为
 * `nonReentrant` 不能互相调用。这可以通过制作来解决
 * 那些函数 `private`，然后添加 `external` `nonReentrant` 条目
 * 指向他们。
 *
 * 提示：如果您想了解更多关于重入和替代方法的信息
 * 为了防止它，请查看我们的博客文章
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    
    // 布尔值比 uint256 或任何占用完整空间的类型更昂贵
    // 字，因为每个写操作都会发出一个额外的 SLOAD 来首先读取
    // slot 的内容，替换布尔值占用的位，然后写入
    // 背部。这是编译器对合约升级的防御
    // 指针别名，不能禁用。

    // 非零值会使部署成本更高，
    // 但作为交换，每次调用 nonReentrant 的退款将在
    // 数量。由于退款上限为总额的百分比
    // 交易的gas，在这种情况下最好保持低，以
    // 增加全额退款生效的可能性。
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     
     * @dev 防止合约直接或间接调用自己。
     * 从另一个 `nonReentrant` 调用 `nonReentrant` 函数
     * 不支持功能。有可能防止这种情况发生
     * 通过将 `nonReentrant` 函数设为外部，并使其调用
     * 执行实际工作的“private”函数。
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        
        // 在第一次调用 nonReentrant 时，_notEntered 将为真
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        // 在此之后对 nonReentrant 的任何调用都将失败
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // 通过再次存储原始值，触发退款（见
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
// File: @elsess/contracts/utils/Context.sol


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
 * @dev 提供有关当前执行上下文的信息，包括
 * 交易的发送者及其数据。虽然这些通常可用
 * 通过 msg.sender 和 msg.data，不应直接访问它们
 * 方式，因为在处理元交易时，帐户发送和
 * 为执行付费可能不是实际的发送者（就应用程序而言
 * 被关注到）。
 * This contract is only required for intermediate, library-like contracts.
 
 * 只有中间的、类似图书馆的合同才需要此合同。
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: ERC721A.sol


// Creators: locationtba.eth, 2pmflow.eth

pragma solidity ^0.8.0;









/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 * @dev https://eips.ethereum.org/EIPS/eip-721[ERC721] 非同质代币标准的实现，包括
 * 元数据和可枚举扩展。专为优化批量铸币过程中的低气体而设计。
 *
 * 假设连续剧从 0 开始按顺序铸造（例如 0、1、2、3..）。
 *
 * 不支持将代币刻录到地址（0）。
 */
contract ERC721A is
Context,
ERC165,
IERC721,
IERC721Metadata,
IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 private currentIndex = 0;

    uint256 internal immutable maxBatchSize;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    // 从令牌 ID 映射到所有权详细信息
    // 一个空的结构值并不一定意味着令牌是无主的。有关详细信息，请参见 ownerOf 实现。
    mapping(uint256 => TokenOwnership) private _ownerships;

    // Mapping owner address to address data
    // 将所有者地址映射到地址数据
    mapping(address => AddressData) private _addressData;


    // 从令牌 ID 到批准地址的映射
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    // 从所有者到操作员批准的映射

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev
     * `maxBatchSize` refers to how much a minter can mint at a time.
     * `maxBatchSize` 是指铸币者一次可以铸币多少。
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_
    ) {
        require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), "ERC721A: global index out of bounds");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     * 这个读取函数是 O(totalSupply)。如果从单独的合约调用，请务必先测试 gas。
     * 它也可能会因集合大小过大（例如 >> 10000）而降级，请针对您的用例进行测试。
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
    {
        require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("ERC721A: unable to get token of owner by index");
    }

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
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721A: balance query for the zero address");
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: number minted query for the zero address"
        );
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
    {
        require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

        uint256 lowestTokenToCheck;
        if (tokenId >= maxBatchSize) {
            lowestTokenToCheck = tokenId - maxBatchSize + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }
        }

        revert("ERC721A: unable to determine the owner of token");
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     * @dev 用于计算 {tokenURI} 的基本 URI。如果设置，则为每个生成的 URI
     * token 将是 `baseURI` 和 `tokenId` 的串联。空的
     * 默认情况下，可以在子合同中覆盖。
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        require(to != owner, "ERC721A: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721A: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), "ERC721A: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
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
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721A: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * @dev 返回 `tokenId` 是否存在。
     *
     * 令牌可以由其所有者或通过 {approve} 或 {setApprovalForAll} 批准的帐户管理。
     *
     * 代币在铸造时开始存在（`_mint`），
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits a {Transfer} event.
     * @dev Mints `quantity` 代币并将它们转移到 `to`。
     *
     * 要求：
     *
     * - `to` 不能是零地址。
     * - `quantity` 不能大于最大批量大小。
     *
     * 发出 {Transfer} 事件。
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "ERC721A: mint to the zero address");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "ERC721A: token already minted");
        require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(
            addressData.balance + uint128(quantity),
            addressData.numberMinted + uint128(quantity)
        );
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                "ERC721A: transfer to non ERC721Receiver implementer"
            );
            updatedIndex++;
        }

        currentIndex = updatedIndex;
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     * @dev 将 `tokenId` 从 `from` 转移到 `to`。
     *
     * 要求：
     *
     * - `to` 不能是零地址。
     * - `tokenId` 令牌必须由 `from` 拥有。
     *
     * 发出 {Transfer} 事件。
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
        getApproved(tokenId) == _msgSender() ||
        isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(
            isApprovedOrOwner,
            "ERC721A: transfer caller is not owner nor approved"
        );

        require(
            prevOwnership.addr == from,
            "ERC721A: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721A: transfer to the zero address");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        // 清除前任所有者的批准
        _approve(address(0), tokenId, prevOwnership.addr);

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
        _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        
        // 如果 tokenId+1 的所有权槽没有显式设置，则表示传输发起者拥有它。
        // 在存储中显式设置 tokenId+1 的槽，以保持 ownerOf(tokenId+1) 调用的正确性。
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = TokenOwnership(
                    prevOwnership.addr,
                    prevOwnership.startTimestamp
                );
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     * @dev 批准 `to` 对 `tokenId` 进行操作
     *
     * 发出 {Approval} 事件。
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    uint256 public nextOwnerToExplicitlySet = 0;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     * @dev 显式设置 `owners` 以消除将来调用 ownerOf() 时的循环
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
        require(quantity > 0, "quantity must be nonzero");
        uint256 endIndex = oldNextOwnerToSet + quantity - 1;
        if (endIndex > currentIndex - 1) {
            endIndex = currentIndex - 1;
        }
        // We know if the last one in the group exists, all in the group exist, due to serial ordering.
        // 我们知道如果组中的最后一个存在，则组中的所有都存在，由于串行排序。
       // require(_exists(endIndex), "还没有足够的铸币来进行清理");
        require(_exists(endIndex), "not enough minted yet for this cleanup");
        for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
            if (_ownerships[i].addr == address(0)) {
                TokenOwnership memory ownership = ownershipOf(i);
                _ownerships[i] = TokenOwnership(
                    ownership.addr,
                    ownership.startTimestamp
                );
            }
        }
        nextOwnerToExplicitlySet = endIndex + 1;
    }

    // /**
    //  * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
    //  * The call is not executed if the target address is not a contract.
    //  *
    //  * @param from address representing the previous owner of the given token ID
    //  * @param to target address that will receive the tokens
    //  * @param tokenId uint256 ID of the token to be transferred
    //  * @param _data bytes optional data to send along with the call
    //  * @return bool whether the call correctly returned the expected magic value
    //  * @dev 在目标地址上调用 {IERC721Receiver-onERC721Received} 的内部函数。
    //  * 如果目标地址不是合约，则不执行调用。
    //  *
    //  * @param from address 代表给定令牌 ID 的先前所有者
    //  * @param 到将接收令牌的目标地址
    //  * @param tokenId uint256 要转移的token的ID
    //  * @param _data bytes 与调用一起发送的可选数据
    //  * @return bool 调用是否正确返回了预期的魔法值
    //  */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
            IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721A: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * @dev Hook 在一组按顺序排列的令牌 ID 即将被传输之前调用。这包括铸币。
     *
     * startTokenId - 要传输的第一个令牌 ID
     * 数量 - 要转移的金额
     *
     * 调用条件：
     *
     * - 当 `from` 和 `to` 都非零时，`from` 的 `tokenId` 将是
     * 转移到`to`。
     * - 当 `from` 为零时，`tokenId` 将为`to` 铸造。
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     
     * @dev Hook 在一组按顺序排列的令牌 id 被传输后调用。这包括
     * 铸币。
     *
     * startTokenId - 要传输的第一个令牌 ID
     * 数量 - 要转移的金额
     *
     * 调用条件：
     *
     * - 当 `from` 和 `to` 都非零时。
     * - `from` 和 `to` 永远不会都是零。
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}
// File: @elsess/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
 * @dev Contract 模块，提供基本的访问控制机制，其中
 * 有一个帐户（所有者）可以被授予独占访问权限
 * 具体功能。
 *
 * 默认情况下，所有者帐户将是部署合约的帐户。这
 * 稍后可以使用 {transferOwnership} 进行更改。
 *
 * 该模块通过继承使用。它将使修饰符可用
 * `onlyOwner`，可以应用于你的函数以限制它们的使用
 * 主人。
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     * 将部署者初始化为初始所有者。  
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     * 返回当前所有者的地址。
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     * 如果被所有者以外的任何帐户调用，则抛出。  
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
     * @dev 离开没有所有者的合同。将无法调用
     * `onlyOwner` 功能不再。只能由当前所有者调用。
     *
     * 注意：放弃所有权将使合同没有所有者，
     * 从而删除仅所有者可用的任何功能
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * @dev 将合约的所有权转移到一个新账户（`newOwner`）。
     * 只能由当前所有者调用。
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     * @dev 将合约的所有权转移到一个新账户（`newOwner`）。
     * 内部功能无访问限制。
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: WeirdoGhostGang.sol


pragma solidity ^0.8.4;





contract WeirdoGhostGang is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;

    uint256 public PRICE = 0.05 ether;

    string private _uri;
    mapping(address => uint256) private _signerOfNum;
    mapping(address => uint256) private _publicNumberMinted;

    //immutable 不可变量 
    //最大供给
    uint256 public immutable maxTotalSupply;
    //预售--
    uint256 public immutable PreMaxMint;
    //售卖
    uint256 public immutable PublicMaxMint;

    //付款
    event PaymentReleased(address to, uint256 amount);

    constructor(string memory initURI, address signer1, address signer2) ERC721A("elsess", "ELS", 3) {
        _uri = initURI;
        maxTotalSupply = 5556;
        PreMaxMint = 2;
        PublicMaxMint = 1;
        _signerOfNum[signer1] = 1;
        _signerOfNum[signer2] = 2;
    }

    function _hash(string calldata salt, address _address) internal view returns (bytes32)
    {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token) internal view returns (uint256)
    {
        return _signerOfNum[_recover(hash, token)] ;
    }

    function _recover(bytes32 hash, bytes memory token) internal pure returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function _baseURI() internal view  override(ERC721A) returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) public virtual onlyOwner{
        _uri = newuri;
    }

    function mint(uint256 num, string calldata salt, bytes calldata token) external payable {
        require(status == Status.PublicSale, "WGGE006");
        require(_verify(_hash(salt, msg.sender), token) >= num, "WGGE001");
        require(publicNumberMinted(msg.sender) + num <= PublicMaxMint, "WGGE008");
        verified(num);
        _safeMint(msg.sender,num);
        _publicNumberMinted[msg.sender] = _publicNumberMinted[msg.sender] + 1;
    }

    function preSaleMint(
        uint256 amount,
        string calldata salt,
        bytes calldata token
    ) external payable {
        require(status == Status.PreSale, "WGGE006");
        uint256 preMaxMint = _verify(_hash(salt, msg.sender), token);
        require(preMaxMint >= amount, "WGGE001");
        require(numberMinted(msg.sender) + amount <= preMaxMint, "WGGE008");
        verified(amount);
        _safeMint(msg.sender, amount);
    }

    function setStatus(Status _status, address signer1, address signer2, address signer3) external onlyOwner {
        status = _status;
        if(status == Status.PublicSale){
            delete _signerOfNum[signer1];
            delete _signerOfNum[signer2];
            _signerOfNum[signer3] = 1;
        }
    }

    function verified(uint256 num) private {
        require(num > 0, 'WGGE011');
        require(msg.value >= PRICE * num, 'WGGE002');
        if (msg.value > PRICE * num) {
            payable(msg.sender).transfer(msg.value - PRICE * num);
        }
        require(totalSupply() + num <= maxTotalSupply, "WGGE003");
        require(tx.origin == msg.sender, "WGGE007");
    }

    function setSignerOfNum(address signer, uint256 num) external onlyOwner {
        _signerOfNum[signer] = num;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function publicNumberMinted(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: number minted query for the zero address"
        );
        return _publicNumberMinted[owner];
    }

    function release() public virtual nonReentrant onlyOwner{
        require(address(this).balance > 0, "WGGE005");
        Address.sendValue(payable(owner()), address(this).balance);
        emit PaymentReleased(owner(), address(this).balance);
    }
}