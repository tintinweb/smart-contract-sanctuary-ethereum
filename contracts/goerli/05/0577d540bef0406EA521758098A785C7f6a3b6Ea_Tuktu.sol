// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IXProgram.sol";
import "./IMatrix.sol";

interface IAccount {
	function InitializeAccount(IXProgram _XProgram, IMatrix _Matrix, address _CommunityFund) external;

	function numReg() external view returns (uint numReg_);

	function CFAccount() external pure returns (uint CFID_);

	function AddressOfAccount(uint _AID) external view returns (address address_);

	function AccountOfAffiliate(string memory _Affiliate) external view returns (uint AID_);

	function AffiliateOfAccount(uint _AID) external view returns (string memory affiliate_);

	function RegistrationTime(uint _AID) external view returns (uint RT_);

	function AccountsOfAddress(address _Address) external view returns (uint[] memory AIDs_);

	function LatestAccountsOfAddress(address _Address) external view returns (uint AID_);

	function ChangeAffiliate(uint _AID, string memory _Affiliate) external;

	function ChangeAddress(uint _AID, address _NewAddress) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IXProgram.sol";
import "./IMatrix.sol";

interface IBalance {
	function InitializeBalance() external;

	function isSupportedToken(IERC20 _Token) external pure returns (bool isSupportedToken_);

	function DefaultStableToken() external pure returns (IERC20 defaultStableToken_);

	function TokenBalanceOf(uint _AID, IERC20 _Token) external view returns (uint balanceOf_);

	function LockedRecycleOf(uint _AID) external view returns (uint lockedR_);

	function LockedUpgradeOf(uint _AID) external view returns (uint lockedU_);

	function TotalBalanceOf(uint _AID) external view returns (uint balanceOf_);

	function AvailableToWithdrawn(uint _AID) external view returns (uint availableToWithdrawn_);

	function AvailableToUpgrade(uint _AID) external view returns (uint availableToUpgrade_);

	function _Locking(uint _AID, uint _LockingFor, uint _Amount) external;

	function _UnLocked(uint _AID, uint _LockingFor, uint _Amount) external;

	function DepositETH(uint _AID, IERC20 _Token, uint _Amount) external payable returns (bool success_);

	function DepositToken(uint _AID, IERC20 _Token, uint _Amount) external returns (bool success_);

	function WithdrawToken(uint _AID, IERC20 _Token, uint _Amount) external returns (bool success_);

	function Withdraw(uint _AID, uint _Amount) external returns (bool success_);

	function TransferToken(
		uint _FromAccount,
		uint _ToAccount,
		IERC20 _Token,
		uint _Amount
	) external returns (bool success_);

	function _TransferReward(uint _FromAccount, uint _ToAccount, uint _Amount) external returns (bool success_);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./IAccount.sol";
import "./IBalance.sol";
import "./ITuktu.sol";

interface IMatrix {
	function _InitMaxtrixes(uint _AID, uint _UU, uint _UB, uint _UT) external;

	function InitializeMatrix(IAccount _Account, IBalance _Balance, ITuktu _Tuktu, uint _StartMatrixIndex) external;

	function _ShareRewardCommunityFund() external;

	function F1OfNode(uint _AID, uint _MATRIX) external view returns (uint[] memory AccountIDs_);

	function UplineOfNode(uint _AID) external view returns (uint UU_, uint UB_, uint UT_);

	function SponsorLevel(uint _AID) external view returns (uint SL_);

	function SponsorLevelTracking(uint _AID) external view returns (uint F1SL2_, uint F1SL5_, uint F2SL2_, uint F3SL2_);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IXProgram.sol";
import "./IMatrix.sol";

interface ITuktu {
	function InitializeTuktu() external;

	function Register(address _nA, uint _UU, uint _UB, uint _UT, uint _LOn, IERC20 _Token) external payable;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./IAccount.sol";
import "./IBalance.sol";
import "./ITuktu.sol";

interface IXProgram {
	function _InitXPrograms(uint _AID, uint _LOn) external;

	function InitializeXProgram(uint _StartXProgramIndex) external;

	function isLevelActivated(uint _AID, uint _XPro, uint _Level) external view returns (bool isLA_);

	function isAutoLevelUp(uint _AID) external view returns (bool isALU_);

	function GetCycleCount(uint _AID, uint _XPro, uint _Level) external view returns (uint cycleCount_);

	function GetPartnerID(
		uint _AID,
		uint _XPro,
		uint _Level,
		uint _Cycle,
		uint _X,
		uint _Y
	) external view returns (uint partnerID_);

	function PirceOfLevelOn(uint _LOn) external view returns (uint pirceOfLevelOn_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Interfaces/IUniswapV2Router02.sol";
import "./Interfaces/IAccount.sol";
import "./Interfaces/IBalance.sol";
import "./Interfaces/ITuktu.sol";
import "./Interfaces/IXProgram.sol";
import "./Interfaces/IMatrix.sol";

uint constant FALSE = 1;
uint constant TRUE = 2;

uint constant UNILEVEL = 1; // Unilevel matrix (Sun, unlimited leg)
uint constant BINARY = 2; // Binary marix - Tow leg
uint constant TERNARY = 3; // Ternary matrix - Three leg

uint constant X3 = 1;
uint constant X6 = 2;
uint constant X7 = 3;
uint constant X8 = 4;
uint constant X9 = 5;

uint constant Line1 = 1;
uint constant Line2 = 2;
uint constant Line3 = 3;

library Algorithms {
	// Factorial x! - Use recursion
	function Factorial(uint _x) internal pure returns (uint _r) {
		if (_x == 0) return 1;
		else return _x * Factorial(_x - 1);
	}

	// Exponentiation x^y - Algorithm: "exponentiation by squaring".
	function Exponential(uint _x, uint _y) internal pure returns (uint _r) {
		// Calculate the first iteration of the loop in advance.
		uint result = _y & 1 > 0 ? _x : 1;
		// Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
		for (_y >>= 1; _y > 0; _y >>= 1) {
			_x = MulDiv18(_x, _x);
			// Equivalent to "y % 2 == 1" but faster.
			if (_y & 1 > 0) {
				result = MulDiv18(result, _x);
			}
		}
		_r = result;
	}

	// https://github.com/paulrberg/prb-math
	// @notice Emitted when the ending result in the fixed-point version of `mulDiv` would overflow uint.
	error MulDiv18Overflow(uint x, uint y);

	function MulDiv18(uint x, uint y) internal pure returns (uint result) {
		// How many trailing decimals can be represented.
		uint UNIT = 1e18;
		// Largest power of two that is a divisor of `UNIT`.
		uint UNIT_LPOTD = 262144;
		// The `UNIT` number inverted mod 2^256.
		uint UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

		uint prod0;
		uint prod1;

		assembly {
			let mm := mulmod(x, y, not(0))
			prod0 := mul(x, y)
			prod1 := sub(sub(mm, prod0), lt(mm, prod0))
		}
		if (prod1 >= UNIT) {
			revert MulDiv18Overflow(x, y);
		}
		uint remainder;
		assembly {
			remainder := mulmod(x, y, UNIT)
		}
		if (prod1 == 0) {
			unchecked {
				return prod0 / UNIT;
			}
		}
		assembly {
			result := mul(
				or(
					div(sub(prod0, remainder), UNIT_LPOTD),
					mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
				),
				UNIT_INVERSE
			)
		}
	}
}

library AffiliateCreator {
	// https://stackoverflow.com/questions/67893318/solidity-how-to-represent-bytes32-as-string
	function ToHex16(bytes16 data) internal pure returns (bytes32 result) {
		result =
			(bytes32(data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
			((bytes32(data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64);
		result =
			(result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
			((result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32);
		result =
			(result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
			((result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16);
		result =
			(result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
			((result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8);
		result =
			((result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4) |
			((result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8);
		result = bytes32(
			0x3030303030303030303030303030303030303030303030303030303030303030 +
				uint(result) +
				(((uint(result) + 0x0606060606060606060606060606060606060606060606060606060606060606) >> 4) &
					0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
				7
		);
	}

	function ToHex(bytes32 data) internal pure returns (string memory) {
		return string(abi.encodePacked("0x", ToHex16(bytes16(data)), ToHex16(bytes16(data << 128))));
	}

	function Create(bytes32 _Bytes32, uint _len) internal pure returns (bytes16 _r) {
		string memory s = ToHex(_Bytes32);
		bytes memory b = bytes(s);
		bytes memory r = new bytes(_len);
		for (uint i; i < _len; ++i) r[i] = b[i + 3];
		return bytes16(bytes(r));
	}

	function Create(uint _AID, uint _len) internal view returns (bytes16 _r) {
		return
			Create(
				bytes32(keccak256(abi.encodePacked(msg.sender, _AID, block.timestamp, block.prevrandao, block.number * _len))),
				_len
			);
	}
}

library AddressLib {
	function isContract(address account) internal view returns (bool _isContract) {
		return account.code.length > 0;
	}
}

library UintArray {
	function RemoveValue(uint[] storage _Array, uint _Value) internal {
		require(_Array.length > 0, "Uint: Can't remove from empty array");
		// Move the last element into the place to delete
		for (uint i = 0; i < _Array.length; ++i) {
			if (_Array[i] == _Value) {
				_Array[i] = _Array[_Array.length - 1];
				break;
			}
		}
		_Array.pop();
	}

	function RemoveIndex(uint[] storage _Array, uint64 _Index) internal {
		require(_Array.length > 0, "Uint: Can't remove from empty array");
		require(_Array.length > _Index, "Index out of range");
		// Move the last element into the place to delete
		_Array[_Index] = _Array[_Array.length - 1];
		_Array.pop();
	}

	function AddNoDuplicate(uint[] storage _Array, uint _Value) internal {
		for (uint i = 0; i < _Array.length; ++i) if (_Array[i] == _Value) return;
		_Array.push(_Value);
	}

	function TrimRight(uint[] memory _Array) internal pure returns (uint[] memory _Return) {
		require(_Array.length > 0, "Uint: Can't trim from empty array");
		uint count;
		for (uint i = 0; i < _Array.length; ++i) {
			if (_Array[i] != 0) count++;
			else break;
		}

		_Return = new uint[](count);
		for (uint j = 0; j < count; ++j) {
			_Return[j] = _Array[j];
		}
	}
}

library UintExt {}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./Library.sol";

abstract contract Account is IAccount, Ownable2Step, ReentrancyGuard {
	using UintArray for uint[];
	using AffiliateCreator for bytes;

	mapping(uint => uint) private RegTimes; // Registration datetime
	mapping(uint => address) private AddressOfAccounts; // Each account has only one address
	mapping(address => uint[]) private AccountIDsOfAddress; // One address can have multiple accounts
	mapping(bytes32 => uint) private AccountOfAffiliates;
	mapping(uint => bytes32) private AffiliateOfAccounts; // User can modify

	// Registered count. It's not total player and it's not total x programer
	// One user has many accounts, an account has many xprograms, each xprogram has 15 level
	uint private num;

	bool public AccountInitialized; // flags

	uint private constant CFID = type(uint256).max; // Community fund id

	IXProgram public XPrograms;
	IMatrix public Matrixes;

	constructor() {}

	modifier notAccountInitialized() {
		require(!AccountInitialized, "Already initialized");
		_;
	}

	modifier onlyXProgramsOrMatrixes() {
		require(
			msg.sender == address(XPrograms) || msg.sender == address(Matrixes),
			"caller is not the XPrograms or Matrixes"
		);
		_;
	}

	modifier OnlyAccountOwner(uint _AID) {
		require(_isExistedAccount(_AID) && msg.sender == AddressOfAccount(_AID), "account: not existed or owner");
		_;
	}

	modifier OnlyAccountExisted(uint _AID) {
		require(_isExistedAccount(_AID), "Account: does not exist");
		_;
	}

	modifier VerifyAmount(uint _Amount) {
		require(_Amount > 0, "amount can not zero");
		_;
	}

	function InitializeAccount(
		IXProgram _XProgram,
		IMatrix _Matrix,
		address _CF
	) public notAccountInitialized onlyOwner {
		XPrograms = _XProgram;
		Matrixes = _Matrix;

		// Community fund, Starting
		_InitAccount(CFID, msg.sender);
		uint k;
		do {
			_InitAccount(block.number + k++, _CF);
		} while (k < 13);

		AccountInitialized = true;
	}

	function _IDCreator() internal returns (uint AID_) {
		while (true) {
			if (!_isExistedAccount(++num)) return num;
		}
	}

	function _AffiliateCreator(uint _AID) private view returns (bytes16 affiliate_) {
		while (true) {
			affiliate_ = AffiliateCreator.Create(_AID, 8);
			if (AccountOfAffiliates[affiliate_] == 0) return affiliate_;
		}
	}

	// Initialize account
	function _InitAccount(uint NewAccountID_, address _Address) internal {
		RegTimes[NewAccountID_] = block.timestamp;
		AddressOfAccounts[NewAccountID_] = _Address;
		AccountIDsOfAddress[_Address].push(NewAccountID_);
		AffiliateOfAccounts[NewAccountID_] = _AffiliateCreator(NewAccountID_);
		AccountOfAffiliates[AffiliateOfAccounts[NewAccountID_]] = NewAccountID_;
	}

	/*----------------------------------------------------------------------------------------------------*/

	function numReg() public view returns (uint numReg_) {
		return num;
	}

	function CFAccount() public pure returns (uint CFID_) {
		return CFID;
	}

	function _isExistedAccount(uint _AID) internal view returns (bool isExist_) {
		return RegTimes[_AID] != 0;
	}

	function AddressOfAccount(uint _AID) public view returns (address address_) {
		return AddressOfAccounts[_AID];
	}

	function AccountOfAffiliate(string memory _Affiliate) public view returns (uint AID_) {
		return AccountOfAffiliates[bytes32(bytes(_Affiliate))];
	}

	function AffiliateOfAccount(uint _AID) public view returns (string memory affiliate_) {
		return string(abi.encode(AffiliateOfAccounts[_AID]));
	}

	function RegistrationTime(uint _AID) public view returns (uint RT_) {
		return RegTimes[_AID];
	}

	// Dashboard
	function AccountsOfAddress(address _Address) public view returns (uint[] memory AIDs_) {
		return AccountIDsOfAddress[_Address];
	}

	function LatestAccountsOfAddress(address _Address) public view virtual returns (uint AID_) {
		uint[] memory accounts = AccountsOfAddress(_Address);
		if (accounts.length > 0) {
			AID_ = accounts[0];
			for (uint i = 1; i < accounts.length; ++i) {
				if (RegTimes[accounts[i]] > RegTimes[AID_]) AID_ = accounts[i];
			}
		}
	}

	// Change affiliate
	function ChangeAffiliate(uint _AID, string memory _Affiliate) public virtual OnlyAccountOwner(_AID) {
		bytes32 aff = bytes32(bytes(_Affiliate));
		require(aff != bytes32(0) && AccountOfAffiliate(_Affiliate) == 0, "Affiliate: existed or empty");

		delete AccountOfAffiliates[AffiliateOfAccounts[_AID]];
		AccountOfAffiliates[aff] = _AID;
		AffiliateOfAccounts[_AID] = aff;
	}

	// Account transfer
	function ChangeAddress(uint _AID, address _NewAddress) public virtual OnlyAccountOwner(_AID) {
		require(_NewAddress != address(0) && AddressOfAccount(_AID) != _NewAddress, "same already exists or zero");

		AddressOfAccounts[_AID] = _NewAddress;
		AccountIDsOfAddress[msg.sender].RemoveValue(_AID);
		AccountIDsOfAddress[_NewAddress].AddNoDuplicate(_AID);
	}
}

/*----------------------------------------------------------------------------------------------------*/

abstract contract Balance is IBalance, Account {
	// BSC MAINNET
	// IERC20 public constant BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
	// IERC20 public constant USDT = address(0x55d398326f99059fF775485246999027B3197955);
	// IERC20 public constant USDC = address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
	// IERC20 public constant DAI = address(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3);

	// IERC20 public constant DEFAULT_STABLE_TOKEN = BUSD;
	// IERC20 public constant WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // Wrap BNB
	// IUniswapV2Router02 public constant UNIROUTER = IUniswapV2Router02(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // Pancake Router

	// GOERLI TESTNET
	IERC20 public constant BUSD = IERC20(0x625617419FB360b62314217e0dB1f2eaFECc0240);
	IERC20 public constant USDT = IERC20(0xEDc23f577c434a2C1bCA91409fae2b8a073380C4);
	IERC20 public constant USDC = IERC20(0x533bdcFF6349d715B6649C116b0D2BD5cEfc4615);
	IERC20 public constant DAI = IERC20(0x15081Ba2750898ec74486F264E65BCc318c29178);

	IERC20 public constant DEFAULT_STABLE_TOKEN = USDT;
	IERC20 public constant WETH = IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); // Wrap ETH
	IUniswapV2Router02 public constant UNIROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // UNI Router

	mapping(uint => mapping(IERC20 => uint)) private balances; // [ACCOUNTID][TOKEN]

	// Recycle is required, recycle fee is equal to level cost (= PirceOfLevel) -> balance needs to be Locked for recycles
	// Required to upgrade after the program's free cycle (Cycle 1: free, cycle 2: require Locked, cycle 3: require upgrade level)
	// -> balance needs to be Locked for required to upgrade level
	mapping(uint => uint[2]) private Locked; // Recycle = 0, Required upgrade = 1

	constructor() Account() {}

	function InitializeBalance() public onlyOwner {}

	modifier OnlySupportedToken(IERC20 _token) {
		require(isSupportedToken(_token), "Token not supported");
		_;
	}

	function isSupportedToken(IERC20 _Token) public pure returns (bool isSupportedToken_) {
		return _Token == BUSD || _Token == USDT || _Token == USDC || _Token == DAI;
	}

	function DefaultStableToken() public pure returns (IERC20 defaultStableToken_) {
		return DEFAULT_STABLE_TOKEN;
	}

	function TokenBalanceOf(uint _AID, IERC20 _Token) public view returns (uint balanceOf_) {
		return balanceOf_ = balances[_AID][_Token];
	}

	function LockedRecycleOf(uint _AID) public view returns (uint lockedR_) {
		return Locked[_AID][0];
	}

	function LockedUpgradeOf(uint _AID) public view returns (uint lockedU_) {
		return Locked[_AID][1];
	}

	function _Locking(uint _AID, uint _LockingFor, uint _Amount) public virtual onlyXProgramsOrMatrixes {
		Locked[_AID][_LockingFor] += _Amount;
	}

	function _UnLocked(uint _AID, uint _UnLockedFor, uint _Amount) public virtual onlyXProgramsOrMatrixes {
		Locked[_AID][_UnLockedFor] -= _Amount;
	}

	function TotalBalanceOf(uint _AID) public view returns (uint totalBalanceOf_) {
		totalBalanceOf_ += TokenBalanceOf(_AID, BUSD);
		totalBalanceOf_ += TokenBalanceOf(_AID, USDT);
		totalBalanceOf_ += TokenBalanceOf(_AID, USDC);
		totalBalanceOf_ += TokenBalanceOf(_AID, DAI);
	}

	function AvailableToWithdrawn(uint _AID) public view returns (uint availableToWithdrawn_) {
		uint locked = LockedRecycleOf(_AID) + LockedUpgradeOf(_AID);
		uint totalbalance = TotalBalanceOf(_AID);
		return totalbalance > locked ? totalbalance - locked : 0;
	}

	function AvailableToUpgrade(uint _AID) public view returns (uint availableToUpgrade_) {
		uint totalbalance = TotalBalanceOf(_AID);
		uint lockedrecycle = LockedRecycleOf(_AID);
		return totalbalance > lockedrecycle ? totalbalance - lockedrecycle : 0;
	}

	function governanceRecoverUnsupported(IERC20 _Token, uint256 _Amount, address _To) external onlyOwner {
		// do not allow to drain supported tokens: BUSD, USDT, USDC, DAI
		require(!isSupportedToken(_Token) || address(_Token) == address(0), "can not drain supported tokens");
		if (address(_Token) != address(0)) _Token.transfer(_To, _Amount);
	}

	/*----------------------------------------------------------------------------------------------------*/

	function AmountETHMin(IERC20 _Token, uint _amountOut) public view returns (uint amountETHMin_) {
		address[] memory path = new address[](2);
		(path[0], path[1]) = (address(WETH), address(_Token));
		return UNIROUTER.getAmountsIn(_amountOut, path)[0];
	}

	// Deposit ETH
	function DepositETH(
		uint _AID,
		IERC20 _Token,
		uint _Amount
	)
		public
		payable
		virtual
		nonReentrant
		OnlySupportedToken(_Token)
		VerifyAmount(_Amount)
		OnlyAccountExisted(_AID)
		returns (bool success_)
	{
		if (msg.value > 0) {
			address[] memory path = new address[](2);
			(path[0], path[1]) = (address(WETH), address(_Token));
			uint deadline = block.timestamp + 30;

			uint[] memory amounts = UNIROUTER.swapETHForExactTokens{ value: msg.value }(
				_Amount,
				path,
				address(this),
				deadline
			);

			if (amounts[1] >= _Amount) {
				balances[_AID][_Token] += _Amount;

				// refund dust eth, if any <- included in uniswap .swapETHForExactTokens
				if (msg.value > amounts[0]) (success_, ) = msg.sender.call{ value: msg.value - amounts[0] }("");

				return true;
			}
		}
	}

	// Deposit specific supported token
	function DepositToken(
		uint _AID,
		IERC20 _Token,
		uint _Amount
	)
		public
		virtual
		nonReentrant
		OnlySupportedToken(_Token)
		VerifyAmount(_Amount)
		OnlyAccountExisted(_AID)
		returns (bool success_)
	{
		// balances[_AID][_Token] += _Amount; // REMIX
		// return true;

		if (_Token.balanceOf(msg.sender) >= _Amount && _Token.transferFrom(msg.sender, address(this), _Amount)) {
			balances[_AID][_Token] += _Amount;
			return true;
		}
	}

	function _WithdrawToken(uint _AID, IERC20 _Token, uint _Amount) private returns (bool success_) {
		balances[_AID][_Token] -= _Amount;
		return _Token.transferFrom(address(this), msg.sender, _Amount);
	}

	// withdrawn specific token
	function WithdrawToken(
		uint _AID,
		IERC20 _Token,
		uint _Amount
	)
		public
		virtual
		nonReentrant
		OnlySupportedToken(_Token)
		VerifyAmount(_Amount)
		OnlyAccountOwner(_AID)
		returns (bool success_)
	{
		require(
			AvailableToWithdrawn(_AID) >= _Amount && TokenBalanceOf(_AID, _Token) >= _Amount,
			"Withdrawn amount exceeds balance"
		);

		Matrixes._ShareRewardCommunityFund(); // To you and other
		return _WithdrawToken(_AID, _Token, _Amount);
	}

	// withdrawn available balance
	function Withdraw(
		uint _AID,
		uint _Amount
	) public virtual nonReentrant VerifyAmount(_Amount) OnlyAccountOwner(_AID) returns (bool success_) {
		require(AvailableToWithdrawn(_AID) >= _Amount, "Withdrawn amount exceeds balance");

		Matrixes._ShareRewardCommunityFund(); // To you and other

		// BUSD
		uint frombalance = TokenBalanceOf(_AID, BUSD);
		if (frombalance > 0) {
			if (frombalance >= _Amount) return _WithdrawToken(_AID, BUSD, _Amount);
			else {
				_Amount -= frombalance;
				_WithdrawToken(_AID, BUSD, frombalance);
			}
		}

		// USDT
		frombalance = TokenBalanceOf(_AID, USDT);
		if (frombalance > 0) {
			if (frombalance >= _Amount) return _WithdrawToken(_AID, USDT, _Amount);
			else {
				_Amount -= frombalance;
				_WithdrawToken(_AID, USDT, frombalance);
			}
		}

		// USDC
		frombalance = TokenBalanceOf(_AID, USDC);
		if (frombalance > 0) {
			if (frombalance >= _Amount) return _WithdrawToken(_AID, USDC, _Amount);
			else {
				_Amount -= frombalance;
				_WithdrawToken(_AID, USDC, frombalance);
			}
		}

		// DAI
		frombalance = TokenBalanceOf(_AID, DAI);
		if (frombalance >= _Amount) return _WithdrawToken(_AID, DAI, _Amount);

		revert("Withdrawn amount exceeds balance");
	}

	function TransferToken(
		uint _FromAccount,
		uint _ToAccount,
		IERC20 _Token,
		uint _Amount
	)
		public
		virtual
		nonReentrant
		OnlySupportedToken(_Token)
		VerifyAmount(_Amount)
		OnlyAccountOwner(_FromAccount)
		OnlyAccountExisted(_ToAccount)
		returns (bool success_)
	{
		require(
			AvailableToWithdrawn(_FromAccount) >= _Amount && TokenBalanceOf(_FromAccount, _Token) >= _Amount,
			"Transfer token amount exceeds balance"
		);

		Matrixes._ShareRewardCommunityFund(); // To you and other
		return _TransferToken(_FromAccount, _ToAccount, _Token, _Amount);
	}

	function _TransferToken(
		uint _FromAccount,
		uint _ToAccount,
		IERC20 _Token,
		uint _Amount
	) private returns (bool success_) {
		balances[_FromAccount][_Token] -= _Amount;
		balances[_ToAccount][_Token] += _Amount;
		return true;
	}

	function _TransferReward(
		uint _FromAccount,
		uint _ToAccount,
		uint _Amount
	)
		external
		nonReentrant
		onlyXProgramsOrMatrixes
		VerifyAmount(_Amount)
		OnlyAccountExisted(_FromAccount)
		OnlyAccountExisted(_ToAccount)
		returns (bool success_)
	{
		require(TotalBalanceOf(_FromAccount) >= _Amount, "transfer reward amount exceeds balance");

		// BUSD
		uint frombalance = TokenBalanceOf(_FromAccount, BUSD);
		if (frombalance > 0) {
			if (frombalance >= _Amount) return _TransferToken(_FromAccount, _ToAccount, BUSD, _Amount);
			else {
				_Amount -= frombalance;
				_TransferToken(_FromAccount, _ToAccount, BUSD, frombalance);
			}
		}

		// USDT
		frombalance = TokenBalanceOf(_FromAccount, USDT);
		if (frombalance > 0) {
			if (frombalance >= _Amount) return _TransferToken(_FromAccount, _ToAccount, USDT, _Amount);
			else {
				_Amount -= frombalance;
				_TransferToken(_FromAccount, _ToAccount, USDT, frombalance);
			}
		}

		// USDC
		frombalance = TokenBalanceOf(_FromAccount, USDC);
		if (frombalance > 0) {
			if (frombalance >= _Amount) return _TransferToken(_FromAccount, _ToAccount, USDC, _Amount);
			else {
				_Amount -= frombalance;
				_TransferToken(_FromAccount, _ToAccount, USDC, frombalance);
			}
		}

		// DAI
		frombalance = TokenBalanceOf(_FromAccount, DAI);
		if (frombalance >= _Amount) return _TransferToken(_FromAccount, _ToAccount, DAI, _Amount);

		revert("transfer reward amount exceeds balance");
	}
}

contract Tuktu is ITuktu, Balance {
	using Address for address;

	event Registration(uint _RT, uint indexed _ID);

	fallback() external {}

	receive() external payable {}

	constructor() Balance() {}

	function InitializeTuktu() public onlyOwner {}

	function Register(address _nA, uint _UU, uint _UB, uint _UT, uint _LOn, IERC20 _Token) public payable {
		if (_nA == address(0)) _nA = msg.sender;
		require(!_nA.isContract(), "Registration: can not contract");
		require(
			_isExistedAccount(_UU) && _isExistedAccount(_UB) && _isExistedAccount(_UT),
			"SID, UB or UT: does not existed"
		);

		if (_LOn < 1 || _LOn > 15) _LOn = 1;
		uint amountUSD = XPrograms.PirceOfLevelOn(_LOn);
		if (!isSupportedToken(_Token)) _Token = DefaultStableToken();
		uint nid = _IDCreator();

		_InitAccount(nid, _nA);
		Matrixes._InitMaxtrixes(nid, _UU, _UB, _UT);

		if (msg.value > 0) {
			if (!DepositETH(nid, _Token, amountUSD)) revert("Deposit eth fail!");
		} else {
			if (!DepositToken(nid, _Token, amountUSD)) revert("Deposit token fail!");
		}

		XPrograms._InitXPrograms(nid, _LOn);

		emit Registration(block.timestamp, nid);
	}
}