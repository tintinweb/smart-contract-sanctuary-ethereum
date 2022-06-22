/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// File: Bnet/Swap/IERC165.sol



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
// File: Bnet/Swap/IERC721.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
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
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
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
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
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
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// File: Bnet/Swap/TransferHelper.sol



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
// File: Bnet/Swap/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: Bnet/Swap/Address.sol

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: Bnet/Swap/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);


    function decimals() external view returns (uint8);


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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// File: Bnet/Swap/SafeERC20.sol

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: Bnet/Swap/Context.sol



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

// File: Bnet/Swap/Ownable.sol

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
// File: Bnet/Swap/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// File: Bnet/Swap/Swap_Core.sol



// 
// * Created By @sajadkoroush
// 
// 
// 
// 

pragma solidity 0.8.10;










contract BNETSwap is Ownable{
    
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public WETH;

    event WithdrawtoOwnerEvent(address indexed Owneraddress, uint256 amount);
    event AddNFTtoFixedSellSwapEvent(address indexed NftContract, uint256 tokenId, address indexed SellerOfToken, address tokenForPay,  uint256 priceNFT, uint256 timeSwap);
    event AddNFTtoBidsSwapEvent(address indexed NftContract, uint256 tokenId, address indexed SellerOfToken, address tokenForPay,  uint256 priceNFT, uint256 timeEnded, uint256 timeListed);
    event BuyNFTitemOnFixedSwapEvent(address indexed NftContract, uint256 tokenId, address indexed SellerOfToken, address tokenForPay,  uint256 priceNFT, uint256 timeSwap);
    event BuyNFTitemOnFixedSwapWithETHEvent(address indexed NftContract, uint256 tokenId, address indexed SellerOfToken, uint256 priceNFT, uint256 timeSwap);
    event NewOwnerOfNftAndShares(address indexed NftContract, uint256 tokenId, address indexed OldOwnerNft, address indexed NewOwnerNft, uint256 SellerShare, uint256 DevShare);
    event TakeBackNFTfromFixedSwap(address indexed NftContract, uint256 tokenId, address OwnerNft);
    event BidAPriceforNft(address indexed NftContract, uint256 tokenId,address SellerOfNft, address OwnerNft, address tokenForPay, uint256 LastPrice, uint256 newPrice);

    struct InfoNFTonFixedSwap{
        address tokenContract;
        uint256 tokenId;
        address OwnerNFT;
        address LastOwnerNFT;
        address tokenMustPayAddress;
        uint256 priceOfItem;
        uint256 timeListed;
        bool isSold;
    }

    struct InfoNFTonBidSwap{
        address tokenContract;
        uint256 tokenId;
        address OwnerNFT;
        address LastOwnerNFT;
        address tokenMustPayAddress;
        uint256 priceOfItem;
        uint256 timeListed;
        uint256 timeEnd;
        uint256 LastPriceOfNFT;
        bool isSold;
    }
    
    mapping(address => mapping(uint256 => InfoNFTonFixedSwap)) public InfoTokensNFTonSwapfixed; 
    mapping(address => mapping(uint256 => bool)) public NFTisExistOnFixedSwap;
    mapping(address => uint256) public NFTOfuserFixed;
    mapping (address => mapping(uint256 => uint256)) public LastPriceForFixed;

    mapping (address => mapping(uint256 => uint256)) public LastPrice;
    mapping (address => mapping(uint256 => InfoNFTonBidSwap)) public InfoTokensNFTonSwapBids;
    mapping (address => mapping(uint256 => bool)) public NFTisExistOnBidsSwap;
    mapping (address => uint256) public NFTOfuserBids;
    mapping (address => mapping(uint256 => address)) public SellerOfNftOnBid;
    address public addressOwner;

    uint256 public NumberOfTokeninFixedSwap = 0;
    uint256 public NumberOfTokeninBidsSwap = 0;
    uint256 public ShareOfSells = 980;
    uint256 public ShareOfDevs = 20;
    uint256 public immutable DivOfShare = 1000;

    constructor(address _owner, address _WETH) {
        addressOwner = _owner;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier onSold(address _tokenContract, uint256 tokenId){
        require(!InfoTokensNFTonSwapfixed[_tokenContract][tokenId].isSold, "It's Not For Sell");
        _;
    }

    function AddNfTforFixedSell(address tokenContract,uint256 tokenId,address tokenMustPayAddress, uint256 amount) external returns(address,uint256,address, uint256){
        //
        //
        //
        // transfer token
        IERC721(tokenContract).safeTransferFrom(msg.sender, address(this), tokenId);

        if(!NFTisExistOnFixedSwap[tokenContract][tokenId]){
            NumberOfTokeninFixedSwap++;
            NFTOfuserFixed[msg.sender]++;
            InfoTokensNFTonSwapfixed[tokenContract][tokenId] = InfoNFTonFixedSwap(tokenContract, tokenId, msg.sender, msg.sender, tokenMustPayAddress, amount, block.timestamp, false);
        }else{
            InfoTokensNFTonSwapfixed[tokenContract][tokenId].OwnerNFT = msg.sender;
            InfoTokensNFTonSwapfixed[tokenContract][tokenId].tokenMustPayAddress = tokenMustPayAddress;
            InfoTokensNFTonSwapfixed[tokenContract][tokenId].priceOfItem = amount;
            InfoTokensNFTonSwapfixed[tokenContract][tokenId].timeListed = block.timestamp;
            InfoTokensNFTonSwapfixed[tokenContract][tokenId].isSold = false;
        } 
        emit AddNFTtoFixedSellSwapEvent(tokenContract, tokenId, msg.sender, tokenMustPayAddress, amount, block.timestamp);       
        return(tokenContract, tokenId, msg.sender, amount);
    }

    function BuyItemNFwithToken(address tokenContract, uint256 tokenId, address tokenMustPayAddress, uint256 amount) public returns(address, uint256, address, uint256, uint256){
        require(NFTisExistOnFixedSwap[tokenContract][tokenId], "NFT is Not Exist");
        require(InfoTokensNFTonSwapfixed[tokenContract][tokenId].priceOfItem <= amount, "Your Price is Not Enough");
        require(InfoTokensNFTonSwapfixed[tokenContract][tokenId].tokenMustPayAddress == tokenMustPayAddress, "token you want to pay is diffrent");
        
        _BuyItemNFTtoken(tokenContract, tokenId, tokenMustPayAddress, amount);
        emit BuyNFTitemOnFixedSwapEvent(tokenContract, tokenId, msg.sender, tokenMustPayAddress, amount, block.timestamp);       
        return(tokenContract, tokenId, msg.sender, amount, block.timestamp);

    }

    function BuyItemNFwithETH(address tokenContract, uint256 tokenId) payable public returns(address, uint256, address, uint256, uint256){
        require(NFTisExistOnFixedSwap[tokenContract][tokenId], "NFT is Not Exist");
        require(InfoTokensNFTonSwapfixed[tokenContract][tokenId].priceOfItem <= msg.value, "Your Price is Not Enough");
        require(InfoTokensNFTonSwapfixed[tokenContract][tokenId].tokenMustPayAddress == WETH, "token you want to pay is diffrent");
        
        IWETH(WETH).deposit{value: msg.value}();
        _BuyItemNFTtoken(tokenContract, tokenId, WETH, msg.value);
        emit BuyNFTitemOnFixedSwapWithETHEvent(tokenContract, tokenId, msg.sender, msg.value, block.timestamp);
        return(tokenContract, tokenId, msg.sender, msg.value, block.timestamp);

    }


    function _BuyItemNFTtoken(address tokenContract, uint256 tokenId, address tokenMustPayAddress, uint256 _amountTokenPay) internal onSold(tokenContract, tokenId) returns(address, uint256, address, uint256, uint256){
        // require(NFTisExistOnFixedSwap[tokenContract][tokenId], "NFT is Not Exist");
        // require(InfoTokensNFTonSwapfixed[tokenContract][tokenId].priceOfItem <= _amount, "Your Price is Not Enough");
        // require(InfoTokensNFTonSwapfixed[tokenContract][tokenId].tokenMustPayAddress == tokenMustPayAddress, "token you want to pay is diffrent");

        address _tokenContract = tokenContract;
        uint256 _tokenId = tokenId;
        address _tokenMustPayAddress = tokenMustPayAddress;
        uint256 _amount = _amountTokenPay;

        InfoTokensNFTonSwapfixed[_tokenContract][_tokenId].LastOwnerNFT = InfoTokensNFTonSwapfixed[_tokenContract][_tokenId].OwnerNFT;
        InfoTokensNFTonSwapfixed[_tokenContract][_tokenId].OwnerNFT = msg.sender;

        uint256 _SellerShareAmount = 0;
        uint256 _DevsShareAmount = 0;

        if(tokenMustPayAddress != WETH){
            IERC20 itoken = IERC20(_tokenMustPayAddress);
            uint256 balancebefore = itoken.balanceOf(address(this));
            itoken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 balanceafter = itoken.balanceOf(address(this));
            _amount = balanceafter - balancebefore;
             _SellerShareAmount = _amount.mul(ShareOfSells).div(DivOfShare);
             _DevsShareAmount = _amount.sub(_SellerShareAmount);
            address _LastOwnerNFT = InfoTokensNFTonSwapfixed[_tokenContract][_tokenId].LastOwnerNFT;
            itoken.safeTransfer(_LastOwnerNFT, _SellerShareAmount);
            itoken.safeTransfer(addressOwner, _DevsShareAmount);

        } else if(tokenMustPayAddress == WETH){
            IWETH(WETH).withdraw(_amount);
            _SellerShareAmount = _amount.mul(ShareOfSells).div(DivOfShare);
            _DevsShareAmount = _amount.sub(_SellerShareAmount);
            TransferHelper.safeTransferETH(InfoTokensNFTonSwapfixed[_tokenContract][_tokenId].LastOwnerNFT, _SellerShareAmount);
            TransferHelper.safeTransferETH(addressOwner, _DevsShareAmount);
        }
        // transfer NFT
        IERC721(_tokenContract).safeTransferFrom(address(this) , msg.sender, InfoTokensNFTonSwapfixed[_tokenContract][_tokenId].tokenId);
        InfoTokensNFTonSwapfixed[_tokenContract][_tokenId].isSold = true;
        InfoTokensNFTonSwapfixed[_tokenContract][_tokenId].timeListed = 0;
        LastPriceForFixed[_tokenContract][_tokenId] = _amount;
        NFTisExistOnFixedSwap[_tokenContract][_tokenId] = false;
        // emit NewOwnerOfNftAndShares(tokenContract, tokenId, InfoTokensNFTonSwapfixed[tokenContract][tokenId].LastOwnerNFT, InfoTokensNFTonSwapfixed[tokenContract][tokenId].OwnerNFT, _SellerShareAmount, _DevsShareAmount);
        return (_tokenContract, _tokenId, msg.sender, _amount, block.timestamp);
    }

    function takeBackNFTtokenToOwnerFixedSwap(address tokenContract, uint256 tokenId) public returns(address, uint256, address){
        require(NFTisExistOnFixedSwap[tokenContract][tokenId], "NFT is Not Exist");
        require(InfoTokensNFTonSwapfixed[tokenContract][tokenId].OwnerNFT == msg.sender, "You are not Owner of this NFT");
        
        IERC721(tokenContract).safeTransferFrom(address(this),msg.sender, InfoTokensNFTonSwapfixed[tokenContract][tokenId].tokenId);
        InfoTokensNFTonSwapfixed[tokenContract][tokenId].isSold = true;
        InfoTokensNFTonSwapfixed[tokenContract][tokenId].priceOfItem = 0;
        emit TakeBackNFTfromFixedSwap(tokenContract, tokenId, msg.sender);
        return (tokenContract, tokenId, msg.sender);
    }

    function AddItemBidSwapNFTonTime(address tokenContract, uint256 tokenId, address tokenMustPayAddress, uint256 amount, uint256 endTime) public returns(address, uint256, address, uint256, uint256, uint256){
        // 
        // 
        //

        // transfer token
        IERC721(tokenContract).safeTransferFrom(msg.sender, address(this), tokenId);

        if(!NFTisExistOnBidsSwap[tokenContract][tokenId]){
            NumberOfTokeninBidsSwap++;
            NFTOfuserBids[msg.sender]++;
            SellerOfNftOnBid[tokenContract][tokenId] = msg.sender;
            InfoTokensNFTonSwapBids[tokenContract][tokenId] = InfoNFTonBidSwap(tokenContract, tokenId, msg.sender, msg.sender, tokenMustPayAddress, amount, block.timestamp, endTime, 0, false);
            LastPrice[tokenContract][tokenId] = 0;
        }else{
            SellerOfNftOnBid[tokenContract][tokenId] = msg.sender;
            InfoTokensNFTonSwapBids[tokenContract][tokenId].OwnerNFT = msg.sender;
            InfoTokensNFTonSwapBids[tokenContract][tokenId].tokenMustPayAddress = tokenMustPayAddress;
            InfoTokensNFTonSwapBids[tokenContract][tokenId].priceOfItem = amount;
            InfoTokensNFTonSwapBids[tokenContract][tokenId].timeListed = block.timestamp;
            InfoTokensNFTonSwapBids[tokenContract][tokenId].timeEnd = endTime;
            InfoTokensNFTonSwapBids[tokenContract][tokenId].isSold = false;
            // Please Check this code 
            LastPrice[tokenContract][tokenId] = amount;
        }        
        emit AddNFTtoBidsSwapEvent(tokenContract, tokenId, msg.sender, tokenMustPayAddress, amount, endTime, block.timestamp);
        return(tokenContract, tokenId, msg.sender, amount, endTime, block.timestamp);
    }

    function BidApriceForNFTpaywithToken(address tokenContract, uint256 tokenId, address tokenMustPayAddress, uint256 amount) public returns(address, uint256, address, uint256, uint256, uint256){
        require(NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is Not Exist");
        require(amount >= InfoTokensNFTonSwapBids[tokenContract][tokenId].priceOfItem ,"Your Price is Not Enough or too Low");
        require(InfoTokensNFTonSwapBids[tokenContract][tokenId].tokenMustPayAddress == tokenMustPayAddress, "token you want to pay is diffrent");
        require(amount >= LastPrice[tokenContract][tokenId], "Your Offer is Low from Last Price");
        uint256 endTime = InfoTokensNFTonSwapBids[tokenContract][tokenId].timeEnd;
        // emit BidAPriceforNft(tokenContract, tokenId, Seller, msg.sender, tokenMustPayAddress, LastPrice, amount);
        _BidApriceForNFTpay(tokenContract, tokenId, tokenMustPayAddress, amount);
        return (tokenContract, tokenId, msg.sender, amount, block.timestamp, endTime);
    }


    function BidApriceForNFTpaywithETH(address tokenContract, uint256 tokenId) payable public returns(address, uint256, address, uint256, uint256){
        require(NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is Not Exist");
        require(InfoTokensNFTonSwapBids[tokenContract][tokenId].priceOfItem <= msg.value, "Your Price is Not Enough");
        require(InfoTokensNFTonSwapBids[tokenContract][tokenId].tokenMustPayAddress == WETH, "token you want to pay is diffrent");
        emit BidAPriceforNft(tokenContract, tokenId, SellerOfNftOnBid[tokenContract][tokenId], msg.sender, WETH, LastPrice[tokenContract][tokenId], msg.value);
        IWETH(WETH).deposit{value: msg.value}();
        _BidApriceForNFTpay(tokenContract, tokenId, WETH, msg.value);
        return(tokenContract, tokenId, msg.sender, msg.value, block.timestamp);
    }


    function _BidApriceForNFTpay(address tokenContract, uint256 tokenId, address tokenforPay, uint _amountToken) internal onSold(tokenContract, tokenId) returns(address, uint256, address, uint256, uint256){
        //
        //
        // requirs
        address _tokenContract = tokenContract;
        uint256 _tokenId = tokenId;
        address _tokenMustPayAddress = tokenforPay;
        uint256 _amount = _amountToken;

        InfoTokensNFTonSwapBids[_tokenContract][_tokenId].LastOwnerNFT = InfoTokensNFTonSwapBids[_tokenContract][_tokenId].OwnerNFT;
        InfoTokensNFTonSwapBids[_tokenContract][_tokenId].OwnerNFT = msg.sender;
        
        uint256 _SellerShareAmount = 0;
        uint256 _DevsShareAmount = 0;

        

        if(_tokenMustPayAddress != WETH){
            IERC20 itoken = IERC20(_tokenMustPayAddress);
            uint256 balancebefore = itoken.balanceOf(address(this));
            itoken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 balanceafter = itoken.balanceOf(address(this));
            _amount = balanceafter - balancebefore;
                if(block.timestamp >= InfoTokensNFTonSwapBids[_tokenContract][_tokenId].timeEnd){
                    _SellerShareAmount = _amount.mul(ShareOfSells).div(DivOfShare);
                    _DevsShareAmount = _amount.sub(_SellerShareAmount);
                    // @dev Please Check it again
                    itoken.safeTransfer(InfoTokensNFTonSwapBids[_tokenContract][_tokenId].LastOwnerNFT, LastPrice[_tokenContract][_tokenId]);
                    itoken.safeTransfer(SellerOfNftOnBid[_tokenContract][_tokenId], _SellerShareAmount);
                    itoken.safeTransfer(addressOwner, _DevsShareAmount);
                    IERC721(_tokenContract).safeTransferFrom(address(this) , InfoTokensNFTonSwapBids[_tokenContract][_tokenId].OwnerNFT, InfoTokensNFTonSwapBids[_tokenContract][_tokenId].tokenId);
                    InfoTokensNFTonSwapBids[_tokenContract][_tokenId].isSold = true;
                    InfoTokensNFTonSwapBids[_tokenContract][_tokenId].timeListed = 0;
                    InfoTokensNFTonSwapBids[_tokenContract][_tokenId].timeEnd = 0;
                    InfoTokensNFTonSwapBids[_tokenContract][_tokenId].LastPriceOfNFT = _amount;
                    LastPrice[_tokenContract][_tokenId] = _amount;
                    emit NewOwnerOfNftAndShares(_tokenContract, _tokenId, InfoTokensNFTonSwapBids[_tokenContract][_tokenId].LastOwnerNFT, InfoTokensNFTonSwapBids[_tokenContract][_tokenId].OwnerNFT, _SellerShareAmount, _DevsShareAmount);
                }else{
                    // @dev Please Check Again;
                    itoken.safeTransfer(InfoTokensNFTonSwapBids[_tokenContract][_tokenId].LastOwnerNFT, LastPrice[_tokenContract][_tokenId]);
                    LastPrice[_tokenContract][_tokenId] = _amount;
                }
        }else if(_tokenMustPayAddress == WETH){
            if(block.timestamp >= InfoTokensNFTonSwapBids[_tokenContract][_tokenId].timeEnd){
                IWETH(WETH).withdraw(_amount);
                _SellerShareAmount = _amount.mul(ShareOfSells).div(DivOfShare);
                _DevsShareAmount = _amount.sub(_SellerShareAmount);
                TransferHelper.safeTransferETH(InfoTokensNFTonSwapBids[_tokenContract][_tokenId].LastOwnerNFT, _SellerShareAmount);
                TransferHelper.safeTransferETH(addressOwner, _DevsShareAmount);
                IERC721(_tokenContract).safeTransferFrom(address(this) , InfoTokensNFTonSwapBids[_tokenContract][_tokenId].OwnerNFT, InfoTokensNFTonSwapBids[_tokenContract][_tokenId].tokenId);
                InfoTokensNFTonSwapBids[_tokenContract][_tokenId].isSold = true;
                InfoTokensNFTonSwapBids[_tokenContract][_tokenId].timeListed = 0;
                InfoTokensNFTonSwapBids[_tokenContract][_tokenId].timeEnd = 0;
                InfoTokensNFTonSwapBids[_tokenContract][_tokenId].LastPriceOfNFT = _amount;
                LastPrice[_tokenContract][_tokenId] = _amount;
                emit NewOwnerOfNftAndShares(_tokenContract, _tokenId, InfoTokensNFTonSwapBids[_tokenContract][_tokenId].LastOwnerNFT, InfoTokensNFTonSwapBids[_tokenContract][_tokenId].OwnerNFT, _SellerShareAmount, _DevsShareAmount);
            }else{
                // @dev Please Check Again;
                IWETH(WETH).withdraw(LastPrice[_tokenContract][_tokenId]);
                TransferHelper.safeTransferETH(InfoTokensNFTonSwapBids[_tokenContract][_tokenId].LastOwnerNFT, LastPrice[_tokenContract][_tokenId]);
                LastPrice[_tokenContract][_tokenId] = _amount;
            }
        }
        return(_tokenContract, _tokenId, msg.sender, _amount, block.timestamp);
    }

    // function takeBackNFTtokenToOwnerBidsSwap(address tokenContract, uint256 tokenId) public returns(address, uint256, address, uint256){
    //     require(NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is Not Exist");
    //     require(InfoTokensNFTonSwapBids[tokenContract][tokenId].OwnerNFT == msg.sender, "You are not Owner of this token");
    //     require(block.timestamp >= InfoTokensNFTonSwapBids[tokenContract][tokenId].timeEnd);
    //     // @dev Check Requires
    //     IERC721(tokenContract).safeTransferFrom(address(this),msg.sender, InfoTokensNFTonSwapBids[tokenContract][tokenId].tokenId);
    //     InfoTokensNFTonSwapBids[tokenContract][tokenId].isSold = true;
    //     InfoTokensNFTonSwapBids[tokenContract][tokenId].priceOfItem = 0;
    //     // event;
    // }

    function _GetNftAfterTimeEnded(address tokenContract, uint256 tokenId) internal returns(address,uint256,address,uint256,uint256) {
        // @dev Check Requires
        InfoTokensNFTonSwapBids[tokenContract][tokenId].LastPriceOfNFT = LastPrice[tokenContract][tokenId];
        uint256 _SellerShareAmount = 0;
        uint256 _DevsShareAmount = 0;
        uint256 _amount = InfoTokensNFTonSwapBids[tokenContract][tokenId].LastPriceOfNFT;
        IERC721(tokenContract).safeTransferFrom(address(this),InfoTokensNFTonSwapBids[tokenContract][tokenId].OwnerNFT, tokenId);
        if(InfoTokensNFTonSwapBids[tokenContract][tokenId].tokenMustPayAddress != WETH){
            IERC20 itoken = IERC20(InfoTokensNFTonSwapBids[tokenContract][tokenId].tokenMustPayAddress);
             _SellerShareAmount = _amount.mul(ShareOfSells).div(DivOfShare);
             _DevsShareAmount = _amount.sub(_SellerShareAmount);
            itoken.safeTransfer(SellerOfNftOnBid[tokenContract][tokenId], _SellerShareAmount);
            itoken.safeTransfer(addressOwner, _DevsShareAmount);
        }else{
            IWETH(WETH).withdraw(_amount);
            _SellerShareAmount = _amount.mul(ShareOfSells).div(DivOfShare);
            _DevsShareAmount = _amount.sub(_SellerShareAmount);
            TransferHelper.safeTransferETH(SellerOfNftOnBid[tokenContract][tokenId], _SellerShareAmount);
            TransferHelper.safeTransferETH(addressOwner, _DevsShareAmount);
        }
        InfoTokensNFTonSwapBids[tokenContract][tokenId].timeListed = 0;
        InfoTokensNFTonSwapBids[tokenContract][tokenId].timeEnd = 0;
        InfoTokensNFTonSwapBids[tokenContract][tokenId].isSold = true;
        NFTisExistOnBidsSwap[tokenContract][tokenId] = false;
        emit NewOwnerOfNftAndShares(tokenContract, tokenId, InfoTokensNFTonSwapBids[tokenContract][tokenId].LastOwnerNFT, InfoTokensNFTonSwapBids[tokenContract][tokenId].OwnerNFT, _SellerShareAmount, _DevsShareAmount);
        delete SellerOfNftOnBid[tokenContract][tokenId];
        return(tokenContract, tokenId, msg.sender, _amount, block.timestamp);
    }

    function GetNftAfterTimeEndedforSeller(address tokenContract, uint256 tokenId) public onSold(tokenContract, tokenId) returns(address, uint256, address, uint256, uint256){
        require(NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is Not Exist");
        require(block.timestamp >= InfoTokensNFTonSwapBids[tokenContract][tokenId].timeEnd, "Time is Not Ended");
        require(SellerOfNftOnBid[tokenContract][tokenId] == msg.sender, "You are not Owner of this NFT");
        return _GetNftAfterTimeEnded(tokenContract, tokenId);
    }

    function GetNftAfterTimeEndedforLastOwner(address tokenContract, uint256 tokenId) public onSold(tokenContract, tokenId) returns(address, uint256, address, uint256, uint256){
        require(NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is Not Exist");
        require(block.timestamp >= InfoTokensNFTonSwapBids[tokenContract][tokenId].timeEnd, "Time is Not Ended");
        require(InfoTokensNFTonSwapBids[tokenContract][tokenId].OwnerNFT == msg.sender, "You are not Owner of this NFT");
        return _GetNftAfterTimeEnded(tokenContract, tokenId);
    }

    // @dev Emergency State
    function WithdrawToOwner(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
        emit WithdrawtoOwnerEvent(_msgSender(), amount);
    }

    // @dev Emergency State
    function WithdrawERC20(IERC20 token, uint256 amount) public onlyOwner returns(bool){
        require(token.transfer(msg.sender, amount), "Transfer failed");
        return true;
    }

    // @dev Emergency State
    function WithdrawERC721(IERC721 token, uint256 tokenId) public onlyOwner returns(bool){
        token.safeTransferFrom(address(this), _msgSender(), tokenId);
        return true;
    }

    function LastPriceOfNft(address tokenContract, uint256 tokenId) public view returns(uint256){
        require(NFTisExistOnFixedSwap[tokenContract][tokenId] || NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is not Exist");
        return ((LastPriceForFixed[tokenContract][tokenId]).add(InfoTokensNFTonSwapBids[tokenContract][tokenId].LastPriceOfNFT));
    }

    function LastPriceOfNftFixedSwap(address tokenContract, uint256 tokenId) public view returns(uint256){
        require(NFTisExistOnFixedSwap[tokenContract][tokenId], "NFT is not Exist");
        return ((LastPriceForFixed[tokenContract][tokenId]));
    }

    function LastPriceOfNftBidsSwap(address tokenContract, uint256 tokenId) public view returns(uint256){
        require(NFTisExistOnBidsSwap[tokenContract][tokenId] , "NFT is not Exist");
        return (InfoTokensNFTonSwapBids[tokenContract][tokenId].LastPriceOfNFT);
    }

    function timeIsEndedOnBidsSwap(address tokenContract, uint256 tokenId) public view returns(uint256){
        require(NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is not Exist");
        return (InfoTokensNFTonSwapBids[tokenContract][tokenId].timeEnd);
    }

    function isSoldOnBidsSwap(address tokenContract, uint256 tokenId) public view returns(bool){
        require(NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is not Exist");
        return (InfoTokensNFTonSwapBids[tokenContract][tokenId].isSold);
    }

    function isSoldOnFixedSwap(address tokenContract, uint256 tokenId) public view returns(bool){
        require(NFTisExistOnFixedSwap[tokenContract][tokenId], "NFT is not Exist");
        return (InfoTokensNFTonSwapfixed[tokenContract][tokenId].isSold);
    }

    function timeIsListedOnBidsSwap(address tokenContract, uint256 tokenId) public view returns(uint256){
        require(NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is not Exist");
        return (InfoTokensNFTonSwapBids[tokenContract][tokenId].timeListed);
    }

    function timeIsListedOnFixedSwap(address tokenContract, uint256 tokenId) public view returns(uint256){
        require(NFTisExistOnFixedSwap[tokenContract][tokenId], "NFT is not Exist");
        return (InfoTokensNFTonSwapfixed[tokenContract][tokenId].timeListed);
    }

    function OwnerofNFTinFixedSwap(address tokenContract, uint256 tokenId) public view returns(address){
        require(NFTisExistOnFixedSwap[tokenContract][tokenId], "NFT is not Exist");
        return (InfoTokensNFTonSwapfixed[tokenContract][tokenId].OwnerNFT);
    }

    function OwnerofNFTinBidsSwap(address tokenContract, uint256 tokenId) public view returns(address){
        require(NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is not Exist");
        return (InfoTokensNFTonSwapBids[tokenContract][tokenId].OwnerNFT);
    }

    function LastOwnerofNFTinBidsSwap(address tokenContract, uint256 tokenId) public view returns(address){
        require(NFTisExistOnBidsSwap[tokenContract][tokenId], "NFT is not Exist");
        return (InfoTokensNFTonSwapBids[tokenContract][tokenId].LastOwnerNFT);
    }
}