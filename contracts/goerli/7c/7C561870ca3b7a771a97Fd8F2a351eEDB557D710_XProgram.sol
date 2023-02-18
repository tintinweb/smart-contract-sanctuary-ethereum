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

abstract contract Matrix is IMatrix, Ownable2Step {
	using UintArray for uint[];

	struct SLTracking {
		uint F1SL2; // number of F1s has sponsor level index from 2 and above
		uint F1SL5;
		uint F2SL2;
		uint F3SL2;
	}
	mapping(uint => SLTracking) private SLTrack;

	mapping(uint => uint) private SLOf; // Sponsor level index of
	mapping(uint => mapping(uint => uint[])) private L1ID; // Line 1 IDs on matrix
	mapping(uint => mapping(uint => uint)) private UID; // Upline id on matrix

	/*----------------------------------------------------------------------------------------------------*/

	mapping(uint => mapping(uint => uint[3])) public CFPending; // Community fund: XR, XS, Amount
	uint[] public CFLookup; // Pending lookup
	bool public CFStatus = true;
	uint public constant CFRatio = 20;

	IAccount public Accounts;
	IBalance public Balances;
	ITuktu public Tuktu;

	bool public MatrixInitialized; // flags

	event LostProfitOverLevel(uint indexed Timestamp, uint indexed AccountID, uint LostAmount);
	event RewardProfit(uint indexed Timestamp, uint indexed AccountID, uint RewardAmount);

	function _PendingToCF(uint _AID, uint _MATRIX, uint _Amount) internal {
		CFPending[_AID][_MATRIX][2] += _Amount;
	}

	function _CFPendingOf(uint _AID, uint _MATRIX) private view returns (uint[3] memory CF_) {
		return CFPending[_AID][_MATRIX];
	}

	function _SetCFPendingOf(uint _AID, uint _MATRIX, uint[3] memory _CF) private {
		CFPending[_AID][_MATRIX] = _CF;
	}

	function _ShareRewardCommunityFund() external {
		if (!CFStatus) return;
		if (CFLookup.length == 0) return;

		uint num = Accounts.numReg();
		if (num <= 20000) return; // For marketing
		if (num > 100000) CFStatus = false; // Stop Community fund

		// num <= 50000: 10% for marketing and rest for upline as tribute to pioneers
		// num <= 100000: all for upline as tribute to pioneers
		uint len = CFLookup.length <= 5 ? CFLookup.length : 5;
		for (uint i; i < len; ++i) {
			_TransferCF(CFLookup[i], BINARY);
			_TransferCF(CFLookup[i], TERNARY);

			CFLookup.RemoveValue(CFLookup[i]);
		}
	}

	function _TransferCF(uint _AID, uint _MATRIX) private {
		(uint xr, uint xs, uint amount) = (
			_CFPendingOf(_AID, _MATRIX)[0],
			_CFPendingOf(_AID, _MATRIX)[1],
			_CFPendingOf(_AID, _MATRIX)[2]
		);

		uint sl = SponsorLevel(_AID);
		uint CFID = Accounts.CFAccount();

		amount = (Accounts.numReg() <= 50000) ? (amount >> 2) : amount >> 1;
		uint amountXR = amount / xr;
		uint amountXS = amount / xs;

		uint distid = _UplineOnMatrix(_AID, _MATRIX);
		for (uint j; j < xr; ++j) {
			if (SponsorLevel(distid) >= sl) {
				j < xs
					? Balances._TransferReward(CFID, distid, (amountXR + amountXS))
					: Balances._TransferReward(CFID, distid, amountXR);
				emit RewardProfit(block.timestamp, _AID, j < xs ? (amountXR + amountXS) : amountXR);
			} else emit LostProfitOverLevel(block.timestamp, _AID, j < xs ? (amountXR + amountXS) : amountXR);

			distid = _UplineOnMatrix(distid, _MATRIX);
		}
		delete CFPending[_AID][_MATRIX][2]; // Amount
	}

	/*----------------------------------------------------------------------------------------------------*/

	modifier onlyAccountOwner(uint _AID) {
		require(
			Accounts.RegistrationTime(_AID) != 0 &&
				(msg.sender == address(Tuktu) || msg.sender == Accounts.AddressOfAccount(_AID)),
			"matrix: not existed or owner"
		);
		_;
	}

	modifier onlyTuktu() {
		require(msg.sender == address(Tuktu), "caller is not tuktu");
		_;
	}

	modifier notMatrixInitialized() {
		require(!MatrixInitialized, "Already initialized");
		_;
	}

	constructor() {}

	function InitializeMatrix(
		IAccount _Account,
		IBalance _Balance,
		ITuktu _Tuktu,
		uint _S
	) public notMatrixInitialized onlyOwner {
		Accounts = _Account;
		Balances = _Balance;
		Tuktu = _Tuktu;

		// _SetSponsorLevel(_S, 15);
		SLOf[_S] = 15;

		uint k;
		do {
			++k;

			// uint _AID = _S + k;
			// uint _SID = _S + (k <= 3 ? 0 : (k <= 6 ? 1 : (k <= 9 ? 2 : 3)));
			// uint _UB = _S +
			// 	(k <= 2 ? 0 : (k <= 4 ? 1 : (k <= 6 ? 3 : (k <= 8 ? 2 : (k <= 9 ? 7 : (k <= 11 ? 5 : 6))))));
			// uint _UT = _S + (k <= 3 ? 0 : (k <= 6 ? 1 : (k <= 9 ? 2 : 3)));

			// _SetSponsorLevel(_AID, _S + k);
			SLOf[_S + k] = 15;

			// Unilevel matrix
			L1ID[_S + (k <= 3 ? 0 : (k <= 6 ? 1 : (k <= 9 ? 2 : 3)))][UNILEVEL].push(_S + k);
			UID[_S + k][UNILEVEL] = _S + (k <= 3 ? 0 : (k <= 6 ? 1 : (k <= 9 ? 2 : 3)));

			// _AddF1OfNode(_SID, UNILEVEL, _AID);
			// _SetUplineOnMatrix(_AID, UNILEVEL, _SID);

			// Binary matrix
			// uint xr = (k <= 2 ? 1 : (k <= 4 ? 2 : (k <= 6 ? 3 : (k <= 8 ? 2 : (k <= 9 ? 3 : 4)))));
			// uint xs = (k <= 2 ? 1 : (k <= 3 ? 2 : (k <= 4 ? 1 : (k <= 6 ? 2 : (k <= 8 ? 1 : 2)))));
			// uint[3] memory cf = [xr, xs, 0];
			// _SetCFPendingOf(_AID, BINARY, cf);

			CFPending[_S + k][BINARY] = [
				(k <= 2 ? 1 : (k <= 4 ? 2 : (k <= 6 ? 3 : (k <= 8 ? 2 : (k <= 9 ? 3 : 4))))),
				(k <= 2 ? 1 : (k <= 3 ? 2 : (k <= 4 ? 1 : (k <= 6 ? 2 : (k <= 8 ? 1 : 2))))),
				0
			];

			L1ID[_S + (k <= 2 ? 0 : (k <= 4 ? 1 : (k <= 6 ? 3 : (k <= 8 ? 2 : (k <= 9 ? 7 : (k <= 11 ? 5 : 6))))))][BINARY]
				.push(_S + k);
			UID[_S + k][BINARY] =
				_S +
				(k <= 2 ? 0 : (k <= 4 ? 1 : (k <= 6 ? 3 : (k <= 8 ? 2 : (k <= 9 ? 7 : (k <= 11 ? 5 : 6))))));

			// _AddF1OfNode(_UB, BINARY, _AID);
			// _SetUplineOnMatrix(_AID, BINARY, _UB);

			// Ternary matrix
			// xr = (k <= 3 ? 1 : 2);
			// xs = 1;
			// cf = [xr, xs, 0];
			// _SetCFPendingOf(_AID, TERNARY, cf);

			CFPending[_S + k][TERNARY] = [(k <= 3 ? 1 : 2), 1, 0];

			L1ID[_S + (k <= 3 ? 0 : (k <= 6 ? 1 : (k <= 9 ? 2 : 3)))][TERNARY].push(_S + k);
			UID[_S + k][TERNARY] = _S + (k <= 3 ? 0 : (k <= 6 ? 1 : (k <= 9 ? 2 : 3)));

			// _AddF1OfNode(_UT, TERNARY, _AID);
			// _SetUplineOnMatrix(_AID, TERNARY, _UT);
		} while (k < 12);

		MatrixInitialized = true;
	}

	// Select all F1 of node in each matrix (for tree view)
	function F1OfNode(uint _AID, uint _MATRIX) public view returns (uint[] memory AIDs_) {
		return L1ID[_AID][_MATRIX];
	}

	function _AddF1OfNode(uint _AID, uint _MATRIX, uint _F1ID) private {
		L1ID[_AID][_MATRIX].push(_F1ID);
	}

	function UplineOfNode(uint _AID) public view returns (uint UU_, uint UB_, uint UT_) {
		return (_UplineOnMatrix(_AID, UNILEVEL), _UplineOnMatrix(_AID, BINARY), _UplineOnMatrix(_AID, TERNARY));
	}

	function _UplineOnMatrix(uint _AID, uint _MATRIX) internal view returns (uint UID_) {
		return UID[_AID][_MATRIX];
	}

	function _SetUplineOnMatrix(uint _AID, uint _MATRIX, uint _UID) private {
		UID[_AID][_MATRIX] = _UID;
	}

	function SponsorLevel(uint _AID) public view returns (uint SL_) {
		return SLOf[_AID];
	}

	function _SetSponsorLevel(uint _AID, uint _SLValue) private {
		SLOf[_AID] = _SLValue;
	}

	function SponsorLevelTracking(uint _AID) public view returns (uint F1SL2_, uint F1SL5_, uint F2SL2_, uint F3SL2_) {
		return (SLTrack[_AID].F1SL2, SLTrack[_AID].F1SL5, SLTrack[_AID].F2SL2, SLTrack[_AID].F3SL2);
	}

	// Initialize new node to Matrixes
	function _InitMaxtrixes(uint _AID, uint _SID, uint _UB, uint _UT) public onlyTuktu {
		_SetSponsorLevel(_AID, 1);

		// Unilevel matrix
		_AddF1OfNode(_SID, UNILEVEL, _AID);
		_SetUplineOnMatrix(_AID, UNILEVEL, _SID);

		// Update sponsor level for upline when node changes from SL1 to SL2
		if (F1OfNode(_SID, UNILEVEL).length == 3 && SponsorLevel(_SID) < 15) _UpdateSponsorLevelForUpline(_AID);

		// Binary matrix
		if (_VerifyUplineID(_AID, _SID, _UB, BINARY)) {
			_AddF1OfNode(_UB, BINARY, _AID);
			_SetUplineOnMatrix(_AID, BINARY, _UB);
		} else revert("Verify UB BINARY: fail");

		// Ternary matrix
		if (_VerifyUplineID(_AID, _SID, _UT, TERNARY)) {
			_AddF1OfNode(_UT, TERNARY, _AID);
			_SetUplineOnMatrix(_AID, TERNARY, _UT);
		} else revert("Verify UT TERNARY: fail");
	}

	// Verify UplineID and update CF
	function _VerifyUplineID(uint _AID, uint _SID, uint _UID, uint _MATRIX) private returns (bool Success_) {
		if (F1OfNode(_UID, _MATRIX).length >= _MATRIX) return (false); // Limited leg

		uint[3] memory cf = _CFPendingOf(_AID, _MATRIX);
		cf[0] = _CFPendingOf(_UID, _MATRIX)[0] + 1; // XR

		if (_SID == _UID) {
			cf[1] = 1; // XS

			if (
				(_UplineOnMatrix(_SID, _MATRIX) == 0 && cf[0] == cf[1]) ||
				(_UplineOnMatrix(_SID, _MATRIX) != 0 && cf[0] != cf[1])
			) {
				_SetCFPendingOf(_AID, _MATRIX, cf);
				return (true);
			}

			return (false);
		}

		uint countxs;
		while (_UID != 0) {
			++countxs;
			if (_UID == _SID) {
				cf[1] = countxs;
				_SetCFPendingOf(_AID, _MATRIX, cf);
				return (true); // Sponsor found, is downline of sponsor
			}
			_UID = _UplineOnMatrix(_UID, _MATRIX);
		}
		return (false); // == 0 [-1] is root, root found
	}

	// Update sponsor level for upline when node changes from SL1 to SL2
	function _UpdateSponsorLevelForUpline(uint _AID) private {
		uint s1 = _UplineOnMatrix(_AID, UNILEVEL);
		SLOf[s1] += 1 + SLTrack[s1].F1SL2; // Here: s1.SL max = 4

		uint s2 = _UplineOnMatrix(s1, UNILEVEL);
		if (s2 == 0) return;
		++SLTrack[s2].F1SL2;
		uint s2sl = SponsorLevel(s2);
		bool s2sl5;
		if (s2sl >= 2 && s2sl <= 4) {
			++s2sl; // Here: s2.SL max = 5
			if (s2sl == 5) {
				s2sl += (SLTrack[s2].F2SL2 >= 9 ? 9 : SLTrack[s2].F2SL2);
				s2sl5 = true;
			}
			_SetSponsorLevel(s2, s2sl); // Here: s2.SL max = 14
		}

		uint s3 = _UplineOnMatrix(s2, UNILEVEL);
		if (s3 == 0) return;
		++SLTrack[s3].F2SL2;
		uint s3sl = SponsorLevel(s3);
		if (s2sl5 && ++SLTrack[s3].F1SL5 >= 10 && s3sl < 15) _SetSponsorLevel(s3, 15);
		if (s3sl >= 5 && s3sl < 14) ++SLOf[s3]; // Here: s3.SL max = 14

		uint s4 = _UplineOnMatrix(s3, UNILEVEL);
		if (s4 == 0) return;
		if (++SLTrack[s4].F3SL2 >= 27 && SponsorLevel(s4) < 15) _SetSponsorLevel(s4, 15);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Matrix.sol";

contract XProgram is IXProgram, Matrix {
	using UintArray for uint[];

	uint public X7Line2Ratio = 30;
	uint public X7Line3Ratio = 70;
	uint public X9Line2Ratio = 30;
	uint public X9Line3Ratio = 70;

	// Pirce of level in each xprogram. 0: Promo, 1-15: level pirce
	uint[16] public PirceOfLevel = [
		0,
		1e18,
		5e18,
		10e18,
		20e18,
		40e18,
		80e18,
		160e18,
		320e18,
		640e18,
		1250e18,
		2500e18,
		5000e18,
		10000e18,
		20000e18,
		40000e18
	];

	struct Cycle {
		mapping(uint => mapping(uint => uint)) XY; // [LINE-X][POS-Y] -> Partner ID
		mapping(uint => uint) XCount; // [LINE-X]
		uint CycleUplineID; // Cycle upline id in each account cycle
	}
	mapping(uint => mapping(uint => mapping(uint => mapping(uint => Cycle)))) private Cycles; // [AID][XPRO][LEVEL][Cycle index]
	mapping(uint => mapping(uint => mapping(uint => uint))) private CycleCounts; // Number of recycle on each level

	mapping(uint => mapping(uint => mapping(uint => uint))) private LA; // The level activated or not
	mapping(uint => mapping(uint => mapping(uint => uint))) private L4U; // Locked for required upgrade status
	mapping(uint => uint) private ALU; // Auto level up

	bool public XProgramInitialized; // flags

	event NewCyclePosition(uint Timestamp, uint indexed AccountID, uint XProgram, uint Level);
	event LostPartnerOverLevel(uint Timestamp, uint indexed AccountID, uint XProgram, uint Level);
	event Recycle(uint Timestamp, uint indexed AccountID, uint XProgram, uint Level);
	event Upgraded(uint Timestamp, uint indexed AccountID, uint XProgram, uint LevelTo);

	modifier notXProgramInitialized() {
		require(!XProgramInitialized, "Already initialized");
		_;
	}

	constructor() Matrix() {}

	function InitializeXProgram(uint _S) public notXProgramInitialized onlyOwner {
		uint k;
		do {
			// _SetLevelActivity(_S + k, X3, 1, true);
			// _SetLevelActivity(_S + k, X3, 2, true);

			LA[_S + k][X3][1] = TRUE;
			LA[_S + k][X3][2] = TRUE;

			for (uint x = X6; x <= X9; ++x) for (uint lv = 1; lv <= 15; ++lv) LA[_S + k][x][lv] = TRUE;
			//_SetLevelActivity(_S + k, x, lv, true);

			++k;
		} while (k < 13);

		XProgramInitialized = true;
	}

	/*----------------------------------------------------------------------------------------------------*/

	// The level activate
	function isLevelActivated(uint _AID, uint _XPro, uint _Level) public view returns (bool isLA_) {
		return LA[_AID][_XPro][_Level] == TRUE ? true : false;
	}

	function _SetLevelActivity(uint _AID, uint _XPro, uint _Level, bool _Status) private {
		LA[_AID][_XPro][_Level] = _Status == true ? TRUE : FALSE;
	}

	// Locked for required upgrade status
	function isLocked4Upgrade(uint _AID, uint _XPro, uint _Level) private view returns (bool isL4U_) {
		return L4U[_AID][_XPro][_Level] == TRUE ? true : false;
	}

	function _SetLock4Upgrade(uint _AID, uint _XPro, uint _Level, bool _Status) private {
		L4U[_AID][_XPro][_Level] = _Status == true ? TRUE : FALSE;
	}

	// Auto level up
	function isAutoLevelUp(uint _AID) public view returns (bool isALU_) {
		return ALU[_AID] == TRUE ? true : false;
	}

	function _SetAutoLevelUp(uint _AID, bool _Status) private {
		ALU[_AID] = _Status == true ? TRUE : FALSE;
	}

	// Cycle count
	function GetCycleCount(uint _AID, uint _XPro, uint _Level) public view returns (uint cycleCount_) {
		return CycleCounts[_AID][_XPro][_Level];
	}

	// Cycle info
	function GetCurrentCycle(uint _AID, uint _XPro, uint _Level) private view returns (Cycle storage currentCycle_) {
		uint Ccurrentcycle = GetCycleCount(_AID, _XPro, _Level);
		return Cycles[_AID][_XPro][_Level][Ccurrentcycle];
	}

	// For dashboard
	function GetPartnerID(
		uint _AID,
		uint _XPro,
		uint _Level,
		uint _Cycle,
		uint _X,
		uint _Y
	) public view returns (uint partnerID_) {
		return Cycles[_AID][_XPro][_Level][_Cycle].XY[_X][_Y];
	}

	/*----------------------------------------------------------------------------------------------------*/

	function PirceOfLevelOn(uint _LOn) public view returns (uint pirceOfLevelOn_) {
		// require(_LOn >= 1 && _LOn <= 15, "PirceOfLevelOn: out of range");
		if (_LOn == 1) return PirceOfLevel[1] * 5;
		else if (_LOn == 2) return (PirceOfLevel[1] + PirceOfLevel[2]) * 5;
		else {
			for (uint i = 3; i <= _LOn; ++i) {
				pirceOfLevelOn_ += PirceOfLevel[i] * 4;
			}
			return pirceOfLevelOn_ + ((PirceOfLevel[1] + PirceOfLevel[2]) * 5);
		}
	}

	function ChangeStatusALU(uint _AID) public virtual onlyAccountOwner(_AID) {
		if (isAutoLevelUp(_AID)) {
			_SetAutoLevelUp(_AID, false);

			if (!isLevelActivated(_AID, X3, 2) && GetCycleCount(_AID, X3, 1) == 0) _UnlockWhenUpgraded(_AID, X3, 2);

			for (uint x = X6; x <= X9; ++x)
				for (uint lv = 2; lv <= 15; ++lv)
					if (!isLevelActivated(_AID, x, lv)) {
						// The first level is not activated yet -> unlock level - 1
						// Only unlock on freecycle (requires level upgrade)
						if (GetCycleCount(_AID, x, lv - 1) == 0) _UnlockWhenUpgraded(_AID, x, lv);
						break;
					}
		} else {
			_SetAutoLevelUp(_AID, true);

			if (!isLevelActivated(_AID, X3, 2)) _LockedToUpgrade(_AID, X3, 2); // X3

			for (uint x = X6; x <= X9; ++x)
				for (uint lv = 2; lv <= 15; ++lv)
					if (!isLevelActivated(_AID, x, lv)) {
						// The first level is not activated yet
						_LockedToUpgrade(_AID, x, lv);
						break;
					}
		}
	}

	/*----------------------------------------------------------------------------------------------------*/

	// Init - Account activation in batches of levels, for reg
	function _InitXPrograms(uint _AID, uint _LOn) external onlyTuktu {
		// X3
		if (_LOn == 1) {
			_FindCurrentCycleUpline(_AID, X3, 1);
			_SetLevelActivity(_AID, X3, 1, true);
		} else {
			_FindCurrentCycleUpline(_AID, X3, 1);
			_SetLevelActivity(_AID, X3, 1, true);

			_FindCurrentCycleUpline(_AID, X3, 2);
			_SetLevelActivity(_AID, X3, 2, true);
		}

		// X6, X8, X7, X9
		for (uint x = X6; x <= X9; ++x) {
			for (uint lv = 1; lv <= _LOn; ++lv) {
				_FindCurrentCycleUpline(_AID, x, lv);
				_SetLevelActivity(_AID, x, lv, true);
			}
		}

		ChangeStatusALU(_AID); // update auto level up status
	}

	// // Account upgrade level manually, fee from wallet
	// function _UpgradeLevelManually(uint _AID, uint _XPro, uint _LTo) internal {
	// 	require(isLevelActivated(_AID, _XPro, _LTo - 1), "Previous level has not been activated");
	// 	// Payable ....
	// 	_UpgradeLevel(_AID, _XPro, _LTo);
	// }

	/*----------------------------------------------------------------------------------------------------*/

	// Upgrade level
	function _UpgradeLevel(uint _AID, uint _XPro, uint _LTo) private {
		require(Balances.AvailableToUpgrade(_AID) >= PirceOfLevel[_LTo], "UpgradeLevel: not enough balance to upgrade");

		// Enough balance
		_FindCurrentCycleUpline(_AID, _XPro, _LTo);
		_SetLevelActivity(_AID, _XPro, _LTo, true);
		emit Upgraded(block.timestamp, _AID, _XPro, _LTo);

		// If locked before, then unlock
		_UnlockWhenUpgraded(_AID, _XPro, _LTo);

		// Auto level up: locked to upgrade to next level
		if (isAutoLevelUp(_AID)) {
			if (_LTo + 1 > 15) return;
			if (_XPro == X3 && _LTo + 1 > 2) return;

			_LockedToUpgrade(_AID, _XPro, _LTo + 1);
		}
	}

	function _LockedToUpgrade(uint _AID, uint _XPro, uint _Level) private {
		if (!isLocked4Upgrade(_AID, _XPro, _Level)) {
			_SetLock4Upgrade(_AID, _XPro, _Level, true);
			Balances._Locking(_AID, 1, PirceOfLevel[_Level]);
		}
	}

	function _UnlockWhenUpgraded(uint _AID, uint _XPro, uint _Level) private {
		if (isLocked4Upgrade(_AID, _XPro, _Level)) {
			_SetLock4Upgrade(_AID, _XPro, _Level, false);
			Balances._UnLocked(_AID, 1, PirceOfLevel[_Level]);
		}
	}

	function _Recycling(uint _AID, uint _XPro, uint _Level) private {
		// Reset current cycle status and find new current upline for account recycling
		// Only on account recycling will the account be checked for the required upgrade

		++CycleCounts[_AID][_XPro][_Level];
		emit Recycle(block.timestamp, _AID, _XPro, _Level);
		_FindCurrentCycleUpline(_AID, _XPro, _Level); // New cycle: Recycling

		// Check required upgrade level
		_CheckRequiredUpgradeLevel(_AID, _XPro, _Level);
	}

	function _CheckRequiredUpgradeLevel(uint _AID, uint _XPro, uint _Level) private {
		if (_Level >= 15) return;
		if (_XPro == X3 && _Level >= 2) return;
		if (isLevelActivated(_AID, _XPro, _Level + 1)) return;

		uint cyclecount = GetCycleCount(_AID, _XPro, _Level);
		// if (recyclecount > 2) return;

		// Cycle 1: free, cycle 2: require locked, cycle 3: require upgrade level
		if (cyclecount == 1) {
			if (isAutoLevelUp(_AID))
				_UpgradeLevel(_AID, _XPro, _Level + 1); // If auto and enough balance then instant upgrade
			else _LockedToUpgrade(_AID, _XPro, _Level + 1); // Not auto or not enough then locked to require upgrade level
		} else _UpgradeLevel(_AID, _XPro, _Level + 1); // recyclecount == 2
	}

	function _ShareReward(uint _AID, uint _XPro, uint _Level) private {
		if (_XPro == X3) {
			//
		} else if (_XPro == X6 || _XPro == X8) {
			//
		} else if (_XPro == X7 || _XPro == X9) {
			uint sr = PirceOfLevel[_Level];
			require(Balances.TotalBalanceOf(_AID) >= sr, "ShareReward: not enough balance to recycle");

			Cycle storage ccu1 = GetCurrentCycle(_AID, _XPro, _Level);
			uint cu1 = ccu1.CycleUplineID;
			if (cu1 == 0) return; // cu1 = 0 means _A = root : do nothing

			if (GetCycleCount(_AID, _XPro, _Level) > 0) Balances._UnLocked(_AID, 0, sr); // unlocked form cycle 2

			Cycle storage ccu2 = GetCurrentCycle(cu1, _XPro, _Level);
			uint cu2 = ccu2.CycleUplineID;
			if (cu2 == 0) {
				Balances._TransferReward(_AID, cu1, sr); // cu2 = 0 means cu1 = root : cu1 gets all the rewards
				return;
			}

			Cycle storage ccu3 = GetCurrentCycle(cu2, _XPro, _Level);
			uint cu3 = ccu3.CycleUplineID;
			if (cu3 == 0) {
				Balances._TransferReward(_AID, cu2, sr); // cu3 = 0 means cu2 = root : cu2 gets all the rewards
				return;
			}

			uint acu2;
			uint acu3;
			if (_XPro == X7) {
				acu2 = (sr * X7Line2Ratio) / 100;
				acu3 = (sr * X7Line3Ratio) / 100;
				// lock for recycle
				if (ccu2.XY[2][4] == _AID) Balances._Locking(cu2, 0, acu2);
				if (ccu3.XY[3][8] == _AID) Balances._Locking(cu3, 0, acu3);
			} else {
				acu2 = (sr * X9Line2Ratio) / 100;
				acu3 = (sr * X9Line3Ratio) / 100;
				// lock for recycle
				if (ccu2.XY[2][9] == _AID) Balances._Locking(cu2, 0, acu2);
				if (ccu3.XY[3][27] == _AID) Balances._Locking(cu3, 0, acu3);
			}

			if (CFStatus) {
				// Community fund actived
				acu2 = ((100 - CFRatio) * acu2) / 100;
				acu3 = ((100 - CFRatio) * acu3) / 100;
				if (Accounts.numReg() > 20000) {
					CFLookup.AddNoDuplicate(_AID);
					_PendingToCF(_AID, TERNARY, (sr - (acu2 + acu3))); // X7, X9: TERNARY
				}
				Balances._TransferReward(_AID, Accounts.CFAccount(), sr - (acu2 + acu3));
			}

			Balances._TransferReward(_AID, cu2, acu2);
			Balances._TransferReward(_AID, cu3, acu3);
		}
	}

	// Find current upline and update for _AID in cycle upline
	function _FindCurrentCycleUpline(uint _AID, uint _XPro, uint _Level) private {
		if (_XPro == X3) {
			//
		} else if (_XPro == X6) {
			//
		} else if (_XPro == X8) {
			//
		} else if (_XPro == X7) {
			//
		} else if (_XPro == X9) {
			uint pendingtorecycle;
			Cycle storage CurrentCycle;
			uint cycleuplineid = _FindCycleUpline(_AID, _XPro, _Level); // C
			CurrentCycle = GetCurrentCycle(cycleuplineid, _XPro, _Level); // C

			if (CurrentCycle.XCount[1] < 3) {
				// Line 1
				uint ay_L1C = ++CurrentCycle.XCount[1]; // Position of _A on line 1 of C
				CurrentCycle.XY[1][ay_L1C] = _AID; // Set _A on C (line 1 of C)

				uint B = CurrentCycle.CycleUplineID;
				if (B != 0) {
					CurrentCycle = GetCurrentCycle(B, _XPro, _Level); // B

					uint cy_L1B;
					if (CurrentCycle.XY[1][1] == cycleuplineid) cy_L1B = 1;
					else if (CurrentCycle.XY[1][2] == cycleuplineid) cy_L1B = 2;
					else if (CurrentCycle.XY[1][3] == cycleuplineid) cy_L1B = 3;

					uint ay_L2B = (((cy_L1B - 1) * 3) + ay_L1C);
					CurrentCycle.XY[2][ay_L2B] = _AID; // Set _A on B (line 2 of B)
					++CurrentCycle.XCount[2];

					uint A = CurrentCycle.CycleUplineID;
					if (A != 0) {
						CurrentCycle = GetCurrentCycle(A, _XPro, _Level);

						uint by_L1A;
						if (CurrentCycle.XY[1][1] == B) by_L1A = 1;
						else if (CurrentCycle.XY[1][2] == B) by_L1A = 2;
						else if (CurrentCycle.XY[1][3] == B) by_L1A = 3;

						uint cy_L2A = (((by_L1A - 1) * 3) + cy_L1B);
						uint ay_L3A = (((cy_L2A - 1) * 3) + ay_L1C);
						CurrentCycle.XY[3][ay_L3A] = _AID; // Set _A on A (line 3 of A)

						if (++CurrentCycle.XCount[3] == 27) pendingtorecycle = A; // Recycling A
					}
				}

				CurrentCycle = GetCurrentCycle(_AID, _XPro, _Level); // _A
				CurrentCycle.CycleUplineID = cycleuplineid; // Update _A: cycleuplineid is (C and is) current cycle upline of _A
				//
			} else if (CurrentCycle.XCount[2] < 9) {
				// line 2 - (cycleuplineid is C and) D is current cycle upline of _A

				uint ay_L2C = ++CurrentCycle.XCount[2]; // Position of _A on line 2 of C
				CurrentCycle.XY[2][ay_L2C] = _AID; // Set _A on C (line 2 of C)

				uint dy_L1C = ay_L2C % 3 == 0 ? (ay_L2C / 3) : ((ay_L2C / 3) + 1); // Position of D on line 1 of C
				uint D = CurrentCycle.XY[1][dy_L1C];
				CurrentCycle = GetCurrentCycle(D, _XPro, _Level);

				uint ay_L1D = ay_L2C % 3 == 0 ? 3 : ay_L2C % 3; // Position of _A on line 1 of D
				CurrentCycle.XY[1][ay_L1D] = _AID; // Set _A on D (line 1 of D)
				++CurrentCycle.XCount[1];

				uint B = CurrentCycle.CycleUplineID;
				if (B != 0) {
					CurrentCycle = GetCurrentCycle(B, _XPro, _Level);

					uint cy_L1B; // Position of C on line 1 of B
					if (CurrentCycle.XY[1][1] == cycleuplineid) cy_L1B = 1;
					else if (CurrentCycle.XY[1][2] == cycleuplineid) cy_L1B = 2;
					else if (CurrentCycle.XY[1][3] == cycleuplineid) cy_L1B = 3;

					uint dy_L2B = (((cy_L1B - 1) * 3) + dy_L1C);
					uint ay_L3B = (((dy_L2B - 1) * 3) + ay_L1D);
					CurrentCycle.XY[3][ay_L3B] = _AID; // Set _A on B (line 3 of B)
					if (++CurrentCycle.XCount[3] == 27) pendingtorecycle = B; // Recycling B
				}

				CurrentCycle = GetCurrentCycle(_AID, _XPro, _Level); // _A
				CurrentCycle.CycleUplineID = D; // Update _AID: D is current cycle upline of _A
				//
			} else if (CurrentCycle.XCount[3] < 27) {
				// line 3 - (cycleuplineid is C and) E is current cycle upline of _A
				uint ay_L3C = ++CurrentCycle.XCount[3]; // Position of _A on line 3 of C
				if (ay_L3C == 27) pendingtorecycle = cycleuplineid; // Recycling C
				CurrentCycle.XY[3][ay_L3C] = _AID; // Set _A on C (line 3 of C)

				uint ey_L2C = ay_L3C % 3 == 0 ? (ay_L3C / 3) : ((ay_L3C / 3) + 1); // Position of E on line 2 of C
				uint E = CurrentCycle.XY[2][ey_L2C];
				CurrentCycle = GetCurrentCycle(E, _XPro, _Level);

				uint ay_L1E = ay_L3C % 3 == 0 ? 3 : ay_L3C % 3; // Position of _A on line 1 of E
				CurrentCycle.XY[1][ay_L1E] = _AID; // Set _A on E (line 1 of E)
				++CurrentCycle.XCount[1];

				uint D = CurrentCycle.CycleUplineID; // D is current upline of E
				CurrentCycle = GetCurrentCycle(D, _XPro, _Level);

				uint ey_L1D = (ey_L2C % 3 == 0 ? 3 : ey_L2C % 3); // Position of E on line 1 of D
				uint ay_L2D = (((ey_L1D - 1) * 3) + ay_L1E); // Position of _A on line 2 of D
				CurrentCycle.XY[2][ay_L2D] = _AID; // Set _A on D (line 2 of D)
				++CurrentCycle.XCount[2];

				CurrentCycle = GetCurrentCycle(_AID, _XPro, _Level); // _A
				CurrentCycle.CycleUplineID = E; // Update _AID: E is current cycle upline of _A
			}

			_ShareReward(_AID, _XPro, _Level); // Share Reward _A to uplines
			if (pendingtorecycle != 0) _Recycling(pendingtorecycle, _XPro, _Level); // Recycling if exist
		}
	}

	function _FindCycleUpline(uint _AID, uint _XPro, uint _Level) private returns (uint CU_) {
		uint aSL = SponsorLevel(_AID);
		uint matrix;
		if (_XPro == X7 || _XPro == X9) matrix = TERNARY;
		else if (_XPro == X6 || _XPro == X8) matrix = BINARY;
		else if (_XPro == X3) matrix = UNILEVEL;

		CU_ = _UplineOnMatrix(_AID, matrix);
		if (CU_ == 0) return _AID;

		while (true) {
			if (SponsorLevel(CU_) >= aSL && isLevelActivated(CU_, _XPro, _Level)) return CU_;
			else emit LostPartnerOverLevel(block.timestamp, CU_, _XPro, _Level);

			if (_UplineOnMatrix(CU_, matrix) == 0) return CU_;
			else CU_ = _UplineOnMatrix(CU_, matrix);
		}

		if (CU_ == 0) revert("_FindCycleUpline return 0 : fail");
	}
}