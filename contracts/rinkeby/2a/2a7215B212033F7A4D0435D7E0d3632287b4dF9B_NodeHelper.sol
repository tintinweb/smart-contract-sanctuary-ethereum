/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {
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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Pool is Ownable {
    IERC20 public ROULETTE;

    constructor(address _ROULETTE) {
        ROULETTE = IERC20(_ROULETTE);
    }

    function pay(address _to, uint _amount) external onlyOwner returns (bool) {
        return ROULETTE.transfer(_to, _amount);
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

interface MansionManager is IERC721 {
    function price(address) external returns(uint256);
    function createNode(address account, string memory nodeName, uint256 tier) external;
    function claim(address account, uint256 _id) external returns (uint);
    function getNameOf(uint256 _id) external view returns (string memory);
    function getMintOf(uint256 _id) external view returns (uint64);
    function getClaimOf(uint256 _id) external view returns (uint64);
    function getTierIndex(address account) external view returns (uint256);
}

// interface RewardToken is IERC20{
//     function nodeApprove(address spender, uint256 amount) external returns (bool);
// }

// interface DistrictHelper {
//   function claim(address account, uint256 _id) external returns (uint);
// }

contract NodeHelper is Ownable {
    MansionManager public manager;
    IERC20 public ROULETTE;
    // DistrictHelper public districtHelper;
    IRouter02 public dexRouter;
    using SafeMath for uint;
    using SafeMath for uint256;

    Pool public pool;

    uint256 public baseFee = 15;
    uint256 public newTax = 0;

    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address private WAVAX;

    address payable public marketingWallet =
        payable(0x462Ca7b60442912C11E801F842ed1a6702De015B);
    address payable public treasuryWallet =
        payable(0x462Ca7b60442912C11E801F842ed1a6702De015B);
    address payable public safeWallet;
    address payable public teamWallet =
        payable(0x462Ca7b60442912C11E801F842ed1a6702De015B);

    address public currentRouter;

    uint256 public claimLiquidityAmount = 0;
    uint256 public claimLiquidityThreshold = 10;
    uint public swapThreshold = 10;
    uint public maxWallet = 200;
    uint public maxMansionTX = 10;

    struct NodeRatios {
        uint16 poolFee;
        uint16 liquidityFee;
        uint16 total;
    }

    NodeRatios public _nodeRatios = NodeRatios({
        poolFee: 70, // reward pool fee
        liquidityFee: 30,
        total: 100
        });

    struct ClaimRatios {
        uint16 rewardPoolFee;
        uint16 liquidityFee;
        uint16 safeFee;
        uint16 teamFee;
        uint16 marketingFee;
        uint16 treasuryFee;
        uint16 total;
    }

    ClaimRatios public _claimRatios = ClaimRatios({
        rewardPoolFee: 8,
        liquidityFee: 3,
        safeFee: 1,
        teamFee: 1,
        marketingFee: 1,
        treasuryFee: 1,
        total: 15
    });

    // struct NewTaxRatios {
    //     uint16 rewards;
    //     uint16 liquidity;
    //     uint16 marketing;
    //     uint16 treasury;
    //     uint16 total;
    // }

    // NewTaxRatios public _newTaxRatios = NewTaxRatios({
    //     rewards: 50,
    //     liquidity: 30,
    //     marketing: 10,
    //     treasury: 10,
    //     total: 100
    // });

    bool private swapLiquify = true;

    // IERC20 public DISTRICT = IERC20(0xfb47FabEf2e2b4032e4AdA60f7a3729be048e07d);

    event AutoLiquify(uint256 amountAVAX, uint256 amount);
    event Transfer(address to, uint256 amount);
    event Received(address, uint);
    
    mapping(address => bool) public blacklist;

    constructor(address _manager, address _ROULETTE)  {
        manager = MansionManager(_manager);
        // districtHelper = DistrictHelper(_district);
        ROULETTE = IERC20(_ROULETTE);
        pool = new Pool(_ROULETTE);
        currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        dexRouter = IRouter02(currentRouter);

        WAVAX = dexRouter.WETH();
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setBlacklisted(address user, bool _val) external onlyOwner {
      blacklist[user] = _val;
    }

    function setWallets(
        address payable marketing,
        address payable treasury,
        address payable team
    ) external onlyOwner {
        marketingWallet = marketing;
        treasuryWallet = treasury;
        teamWallet = team;
    }

    function setSafeWallet(address payable _safeWallet) public onlyOwner {
        safeWallet = _safeWallet;
    }

    // function setTreasury(address _TREASURY) external onlyOwner {
    //     treasuryWallet = payable(_TREASURY);
    // }

    // function setNewUpgrade(IERC20 _DISTRICT) external onlyOwner {
    //     DISTRICT = IERC20(_DISTRICT);
    // }

    // function setNewDistrictHelper(address _district) external onlyOwner {
    //     districtHelper = DistrictHelper(_district);
    // }

    function approveTokenOnRouter() external onlyOwner{
        ROULETTE.approve(currentRouter, type(uint256).max);
    }

    function updatePoolAddress(address _pool) external onlyOwner {
        pool.pay(address(owner()), ROULETTE.balanceOf(address(pool)));
        pool = new Pool(_pool);
    }

    function updateManager(MansionManager _newManager) external onlyOwner {
        manager = MansionManager(_newManager);
    }

    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function updateBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee;
    }

    function updateNewTax(uint256 _newTax) external onlyOwner {
        newTax = _newTax;
    }

    function updateMaxMansionTX(uint256 _maxMansionTX) external onlyOwner {
        maxMansionTX = _maxMansionTX;
    }

    function updateMarketingWallet(address payable _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

   function setNodeRatios(uint16 _poolFee, uint16 _liquidityFee) external onlyOwner {
        _nodeRatios.poolFee = _poolFee;
        _nodeRatios.liquidityFee = _liquidityFee;
        _nodeRatios.total = _poolFee + _liquidityFee;
    }

    function setClaimRatios(
        uint16 _rewardPoolFee,
        uint16 _liquidityFee,
        uint16 _safeFee, 
        uint16 _teamFee,
        uint16 _marketingFee,
        uint16 _treasuryFee
    ) external onlyOwner {
        _claimRatios.rewardPoolFee = _rewardPoolFee;
        _claimRatios.liquidityFee = _liquidityFee;
        _claimRatios.safeFee = _safeFee;
        _claimRatios.teamFee = _teamFee;
        _claimRatios.marketingFee = _marketingFee;
        _claimRatios.treasuryFee = _treasuryFee;
        
        _claimRatios.total = _rewardPoolFee + _liquidityFee + _safeFee + _teamFee + _marketingFee + _treasuryFee;
    }

    // function setNewTaxRatios(uint16 _rewardsFee, uint16 _marketingFee, uint16 _liquidityFee, uint16 _treasuryFee) external onlyOwner {
    //     _newTaxRatios.rewards = _rewardsFee;
    //     _newTaxRatios.marketing = _marketingFee;
    //     _newTaxRatios.liquidity = _liquidityFee;
    //     _newTaxRatios.treasury = _treasuryFee;
    //     _newTaxRatios.total = _rewardsFee + _marketingFee + _liquidityFee + _treasuryFee;
    // }

    function setClaimLiquidityThreshold(uint256 _amount) external onlyOwner {
      claimLiquidityThreshold = _amount;
    }

    function tokenApprovals() external onlyOwner {
        ROULETTE.approve(address(dexRouter), 2000000 * 10^18);
    }

    function setNewRouter(address _dexRouter) external onlyOwner() {
        dexRouter = IRouter02(_dexRouter);
    }

    function contractSwap(uint256 numTokensToSwap) internal {
        if (_nodeRatios.total == 0) {
            return;
        }

        uint256 amountToLiquify = ((numTokensToSwap * _nodeRatios.liquidityFee) / (_nodeRatios.total)) / 2;
        uint256 amountToRewardsPool = (numTokensToSwap * _nodeRatios.poolFee) / (_nodeRatios.total);

        if(amountToRewardsPool > 0) {
            ROULETTE.transfer(address(pool), amountToRewardsPool);
        }

        address[] memory path = new address[](2);
        path[0] = address(ROULETTE);
        path[1] = WAVAX;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToLiquify,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountAVAX = address(this).balance;

        if (amountToLiquify > 0) {
            dexRouter.addLiquidityETH{value: amountAVAX}(
                address(ROULETTE),
                amountToLiquify,
                0,
                0,
                marketingWallet,
                block.timestamp
            );
            emit AutoLiquify(amountAVAX, amountToLiquify);
        }
    }

    function claimContractSwap(uint256 numTokensToSwap) internal {
        // address[] memory path = new address[](2);
        // path[0] = address(ROULETTE);
        // path[1] = WAVAX;

        // dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        //     numTokensToSwap,
        //     0,
        //     path,
        //     address(this),
        //     block.timestamp
        // );

        uint256 amountAVAX = address(this).balance;

        dexRouter.addLiquidityETH{value: amountAVAX}(
            address(ROULETTE),
            numTokensToSwap,
            0,
            0,
            marketingWallet,
            block.timestamp
        );
        emit AutoLiquify(amountAVAX, numTokensToSwap);
        claimLiquidityAmount = 0;
    }

    function createNodeWithTokens(string memory name) public {
        require(bytes(name).length > 0 && bytes(name).length < 33, "HELPER: name size is invalid");
        address sender = _msgSender();
        require(sender != address(0), "HELPER:  Creation from the zero address");
        uint256 nodePrice = manager.price(sender) * 10 ** 18;
        require(nodePrice > 0, "error");
        require(ROULETTE.balanceOf(sender) >= nodePrice, "HELPER: Balance too low for creation.");
        require(manager.balanceOf(sender) + 1 < maxWallet, "HELPER: Exceeds max wallet amount");
        ROULETTE.transferFrom(_msgSender(), address(this),  nodePrice);
        uint256 tier = manager.getTierIndex(sender);
        manager.createNode(sender, name, tier);
    }

    function createMultipleNodeWithTokens(string memory name, uint amount) public {
        require(amount <= maxMansionTX, "HELPER: Exceeds max transaction amount");
        require(bytes(name).length > 0 && bytes(name).length < 33, "HELPER: name size is invalid");
        address sender = _msgSender();
        require(sender != address(0), "HELPER:  Creation from the zero address");
        require(sender != address(0), "HELPER:  Creation from the zero address");
        uint256 nodePrice = manager.price(sender) * 10 ** 18;
        require(ROULETTE.balanceOf(sender) >= nodePrice * amount, "HELPER: Balance too low for creation.");
        require(manager.balanceOf(sender) + amount < maxWallet, "HELPER: Exceeds max wallet amount");
        ROULETTE.transferFrom(_msgSender(), address(this),  nodePrice * amount);
        uint256 tier;
        for (uint256 i = 0; i < amount; i++) {
            tier = manager.getTierIndex(sender);
            manager.createNode(sender, name, tier);
        }

        if ((ROULETTE.balanceOf(address(this)) > swapThreshold)) {
            uint256 contractTokenBalance = ROULETTE.balanceOf(address(this));
            contractSwap(contractTokenBalance);
        }
    }

    function createMultipleNodeWithTokensAndName(string[] memory names, uint amount) public {
        require(amount <= maxMansionTX, "HELPER: Exceeds max transaction amount");
        require(names.length == amount, "HELPER: You need to provide exactly matching names");
        address sender = _msgSender();
        require(sender != address(0), "HELPER:  creation from the zero address");
        uint256 nodePrice = manager.price(sender) * 10 ** 18;
        require(ROULETTE.balanceOf(sender) >= nodePrice * amount, "HELPER: Balance too low for creation.");
        require(manager.balanceOf(sender) + amount < maxWallet, "HELPER: Exceeds max wallet amount");
        ROULETTE.transferFrom(_msgSender(), address(this), nodePrice * amount);
        uint256 tier;
        for (uint256 i = 0; i < amount; i++) {
            string memory name = names[i];
            require(bytes(name).length > 0 && bytes(name).length < 33, "HELPER: name size is invalid");
            tier = manager.getTierIndex(sender);
            manager.createNode(sender, name, tier); 
        }

        if ((ROULETTE.balanceOf(address(this)) > swapThreshold)) {
            uint256 contractTokenBalance = ROULETTE.balanceOf(address(this));
            contractSwap(contractTokenBalance);
        }
    }

    function createNodesWithRewards(string memory name, uint64[] calldata _nodes, uint256 amount, bool useBalance) public {
        require(amount <= maxMansionTX, "HELPER: Exceeds max transaction amount");
        address sender = _msgSender();
        require(sender != address(0), "HELPER: creation from the zero address");
        require(blacklist[sender] == false, "HELPER: You are blacklisted");

        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < _nodes.length; i++) {
            rewardAmount = rewardAmount + manager.claim(_msgSender(), _nodes[i]);
        }

        uint256 nodePrice = manager.price(sender) * 10 ** 18;
        if (!useBalance) require(rewardAmount >= nodePrice * amount,"HELPER: You don't have enough reward to cash out");
        else require(useBalance && rewardAmount + ROULETTE.balanceOf(sender) >= nodePrice * amount,"HELPER: You don't have enough reward to cash out");

        require(manager.balanceOf(sender) + amount < maxWallet, "HELPER: Exceeds max wallet amount");
        uint256 tier;
        for (uint256 i = 0; i < amount; i++) {
            require(bytes(name).length > 0 && bytes(name).length < 33, "HELPER: name size is invalid");
            tier = manager.getTierIndex(sender);
            manager.createNode(sender, name, tier); 
        }

        if (rewardAmount > nodePrice * amount) {
            uint256 remainingRewards = rewardAmount - nodePrice * amount;
            uint256 feeAmount = remainingRewards.mul(getClaimFee()).div(100);
            uint256 excessRewards = remainingRewards - feeAmount;
            pool.pay(sender, excessRewards);
            uint256 amountToCollect = (feeAmount * _claimRatios.marketingFee) / (_claimRatios.total);
            pool.pay(address(this), amountToCollect);
        } else if (useBalance && rewardAmount + ROULETTE.balanceOf(sender) >= nodePrice * amount) {
            uint256 balanceToTransfer = nodePrice * amount - rewardAmount;
            ROULETTE.transferFrom(_msgSender(), address(this),  balanceToTransfer);
            if ((ROULETTE.balanceOf(address(this)) > swapThreshold)) {
                uint256 contractTokenBalance = ROULETTE.balanceOf(address(this));
                contractSwap(contractTokenBalance);
            }
        }
    }

    function getClaimFee () public view returns (uint256) {
        return baseFee;
        // uint256 claimFee;
        // if(DISTRICT.balanceOf(sender) >= baseFee) {
        //     return 0;
        // }        
        // else {
        //     claimFee = baseFee.sub(DISTRICT.balanceOf(sender));
        //     return claimFee;
        // }
    }

    function claimAll(uint64[] calldata _nodes) public {
        address sender = _msgSender();
        require(sender != address(0), "HELPER: creation from the zero address");
        require(blacklist[sender] == false, "HELPER: You are blacklisted");
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < _nodes.length; i++) {
            rewardAmount = rewardAmount + manager.claim(_msgSender(), _nodes[i]);
        }
        require(rewardAmount > 0,"HELPER: You don't have enough reward to cash out");
        uint256 feeAmount = rewardAmount.mul(getClaimFee()).div(100);
        uint256 newFeeAmount = rewardAmount.mul(newTax).div(100);
        require(feeAmount > 0, "Helper: Error");
        if (getClaimFee() > 0) {
            uint256 realReward = rewardAmount - feeAmount - newFeeAmount;
            pool.pay(sender, realReward);

            uint256 rewardPoolAmountfee = feeAmount * _claimRatios.rewardPoolFee / _claimRatios.total;
            uint256 liquidityAmount = feeAmount * _claimRatios.liquidityFee / _claimRatios.total / 2;
            uint256 restAmount = feeAmount - rewardPoolAmountfee;
            pool.pay(address(this), restAmount);
            // MARKETING
            // uint256 amountToMarketingWallet = (feeAmount * _claimRatios.marketingFee) / (_claimRatios.total) + (newFeeAmount * _newTaxRatios.marketing) / _newTaxRatios.total;
            // pool.pay(address(this), amountToMarketingWallet);
            address[] memory path = new address[](2);
            path[0] = address(ROULETTE);
            path[1] = WAVAX;
            dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                restAmount - liquidityAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
            claimContractSwap(liquidityAmount);
            uint256 total = address(this).balance;
            uint256 totalDivisorForETH = _claimRatios.marketingFee + _claimRatios.safeFee + _claimRatios.teamFee + _claimRatios.treasuryFee;
            uint256 marketingFeeAmount = total * _claimRatios.marketingFee / totalDivisorForETH;
            uint256 safeFeeAmount = total * _claimRatios.safeFee / totalDivisorForETH;
            uint256 teamFeeAmount = total * _claimRatios.teamFee / totalDivisorForETH;
            marketingWallet.transfer(marketingFeeAmount);
            safeWallet.transfer(safeFeeAmount);
            teamWallet.transfer(teamFeeAmount);
            treasuryWallet.transfer(address(this).balance);
            // if (newTax > 0) {
            //   // REWARDS POOL -> JUST DON'T TRANSFER ANYTHING, ALREADY IN THE POOL
              
            //   // TREASURY
            //   uint256 amountToTreasury = (newFeeAmount * _newTaxRatios.treasury) / _newTaxRatios.total;
            //   pool.pay(address(this), amountToTreasury);
            //   dexRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            //       amountToTreasury,
            //       0,
            //       path,
            //       treasuryWallet,
            //       block.timestamp
            //   );
              
            //   // LIQUIDITY 
            //   uint256 amountToLiquidity = (newFeeAmount * _newTaxRatios.liquidity) / _newTaxRatios.total;
            //   claimLiquidityAmount += amountToLiquidity;
            //   if (claimLiquidityAmount >= claimLiquidityThreshold) {
            //     pool.pay(address(this), claimLiquidityAmount);
            //     claimContractSwap(claimLiquidityAmount);
            //   }
            // }
        }
        else {
            pool.pay(sender, rewardAmount);
        }
    }

    // function claimDistricts(uint64[] calldata _nodes) public {
    //     address sender = _msgSender();
    //     require(sender != address(0), "HELPER: creation from the zero address");
    //     require(blacklist[sender] == false, "HELPER: You are blacklisted");
    //     uint256 rewardAmount = 0;
    //     for (uint256 i = 0; i < _nodes.length; i++) {
    //         rewardAmount = rewardAmount + districtHelper.claim(_msgSender(), _nodes[i]);
    //     }
    //     require(rewardAmount > 0,"HELPER: You don't have enough reward to cash out");
    //     uint256 feeAmount = rewardAmount.mul(getClaimFee(sender)).div(100);
    //     require(feeAmount > 0, "Helper: Error");
    //     if (getClaimFee(sender) > 0) {
    //         uint256 realReward = rewardAmount - feeAmount;
    //         pool.pay(sender, realReward);

    //         uint256 amountToMarketingWallet = (feeAmount * _claimRatios.marketingFee) / (_claimRatios.total);

    //         pool.pay(address(this), amountToMarketingWallet);

    //         address[] memory path = new address[](2);
    //         path[0] = address(ROULETTE);
    //         path[1] = WAVAX;

    //         dexRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
    //             amountToMarketingWallet,
    //             0,
    //             path,
    //             marketingWallet,
    //             block.timestamp
    //         );
    //     }
    //     else {
    //         pool.pay(sender, rewardAmount);
    //     }
    // }

    function claim(uint64 _node) public {
        address sender = _msgSender();
        require(sender != address(0), "HELPER: creation from the zero address");
        require(blacklist[sender] == false, "HELPER: You are blacklisted");
        uint256 rewardAmount = manager.claim(_msgSender(), _node);
        require(rewardAmount > 0,"HELPER: You don't have enough reward to cash out");
        uint256 feeAmount = rewardAmount.mul(getClaimFee()).div(100);
        uint256 newFeeAmount = rewardAmount.mul(newTax).div(100);
        require(feeAmount > 0, "Helper: Error");
        if (getClaimFee() > 0) {
            uint256 realReward = rewardAmount - feeAmount - newFeeAmount;
            pool.pay(sender, realReward);

            uint256 rewardPoolAmountfee = feeAmount * _claimRatios.rewardPoolFee / _claimRatios.total;
            uint256 liquidityAmount = feeAmount * _claimRatios.liquidityFee / _claimRatios.total / 2;
            uint256 restAmount = feeAmount - rewardPoolAmountfee;
            pool.pay(address(this), restAmount);
            // MARKETING
            // uint256 amountToMarketingWallet = (feeAmount * _claimRatios.marketingFee) / (_claimRatios.total) + (newFeeAmount * _newTaxRatios.marketing) / _newTaxRatios.total;
            // pool.pay(address(this), amountToMarketingWallet);
            address[] memory path = new address[](2);
            path[0] = address(ROULETTE);
            path[1] = WAVAX;
            dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                restAmount - liquidityAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
            claimContractSwap(liquidityAmount);
            uint256 total = address(this).balance;
            uint256 totalDivisorForETH = _claimRatios.marketingFee + _claimRatios.safeFee + _claimRatios.teamFee + _claimRatios.treasuryFee;
            uint256 marketingFeeAmount = total * _claimRatios.marketingFee / totalDivisorForETH;
            uint256 safeFeeAmount = total * _claimRatios.safeFee / totalDivisorForETH;
            uint256 teamFeeAmount = total * _claimRatios.teamFee / totalDivisorForETH;
            marketingWallet.transfer(marketingFeeAmount);
            safeWallet.transfer(safeFeeAmount);
            teamWallet.transfer(teamFeeAmount);
            treasuryWallet.transfer(address(this).balance);

            // if (newTax > 0) {
            //   // REWARDS POOL -> JUST DON'T TRANSFER ANYTHING, ALREADY IN THE POOL
              
            //   // TREASURY
            //   uint256 amountToTreasury = (newFeeAmount * _newTaxRatios.treasury) / _newTaxRatios.total;
            //   pool.pay(address(this), amountToTreasury);
            //   dexRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            //       amountToTreasury,
            //       0,
            //       path,
            //       treasuryWallet,
            //       block.timestamp
            //   );
              
            //   // LIQUIDITY 
            //   uint256 amountToLiquidity = (newFeeAmount * _newTaxRatios.liquidity) / _newTaxRatios.total;
            //   claimLiquidityAmount += amountToLiquidity;
            //   if (claimLiquidityAmount >= claimLiquidityThreshold) {
            //     pool.pay(address(this), claimLiquidityAmount);
            //     claimContractSwap(claimLiquidityAmount);
            //   }
            // }
        }
        else {
            pool.pay(sender, rewardAmount);
        }
    }
}