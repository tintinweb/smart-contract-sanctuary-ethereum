/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: IBasicRewards

interface IBasicRewards {
    function stakeFor(address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function earned(address) external view returns (uint256);

    function withdrawAll(bool) external returns (bool);

    function withdraw(uint256, bool) external returns (bool);

    function getReward() external returns (bool);

    function stake(uint256) external returns (bool);
}

// Part: IBooster

interface IBooster {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);
}

// Part: ICVXLocker

interface ICVXLocker {
    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function balances(address _user)
        external
        view
        returns (
            uint112 locked,
            uint112 boosted,
            uint32 nextUnlockIndex
        );
}

// Part: ICurveFactoryPool

interface ICurveFactoryPool {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_balances() external view returns (uint256[2] memory);

    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256);
}

// Part: ICurveTriCrypto

interface ICurveTriCrypto {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable;

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);
}

// Part: ICurveV2Pool

interface ICurveV2Pool {
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);
}

// Part: IMerkleDistributorV2

interface IMerkleDistributorV2 {
    enum Option {
        Claim,
        ClaimAsETH,
        ClaimAsCRV,
        ClaimAsCVX,
        ClaimAndStake
    }

    function vault() external view returns (address);

    function merkleRoot() external view returns (bytes32);

    function week() external view returns (uint32);

    function frozen() external view returns (bool);

    function isClaimed(uint256 index) external view returns (bool);

    function setApprovals() external;

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    function claimAs(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        Option option
    ) external;

    function claimAs(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        Option option,
        uint256 minAmountOut
    ) external;

    function freeze() external;

    function unfreeze() external;

    function stake() external;

    function updateMerkleRoot(bytes32 newMerkleRoot, bool unfreeze) external;

    function updateDepositor(address newDepositor) external;

    function updateAdmin(address newAdmin) external;

    function updateVault(address newVault) external;

    event Claimed(
        uint256 index,
        uint256 amount,
        address indexed account,
        uint256 indexed week,
        Option option
    );

    event DepositorUpdated(
        address indexed oldDepositor,
        address indexed newDepositor
    );

    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);

    event VaultUpdated(address indexed oldVault, address indexed newVault);

    event MerkleRootUpdated(bytes32 indexed merkleRoot, uint32 indexed week);
}

// Part: IRewards

interface IRewards {
    function balanceOf(address) external view returns (uint256);

    function stake(address, uint256) external;

    function stakeFor(address, uint256) external;

    function withdraw(address, uint256) external;

    function exit(address) external;

    function getReward(address) external;

    function queueNewRewards(uint256) external;

    function notifyRewardAmount(uint256) external;

    function addExtraReward(address) external;

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function earned(address account) external view returns (uint256);
}

// Part: ITriPool

interface ITriPool {
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function get_virtual_price() external view returns (uint256);
}

// Part: IUniV2Router

interface IUniV2Router {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// Part: IUnionVault

interface IUnionVault {
    enum Option {
        Claim,
        ClaimAsETH,
        ClaimAsCRV,
        ClaimAsCVX,
        ClaimAndStake
    }

    function withdraw(address _to, uint256 _shares)
        external
        returns (uint256 withdrawn);

    function withdrawAll(address _to) external returns (uint256 withdrawn);

    function withdrawAs(
        address _to,
        uint256 _shares,
        Option option
    ) external;

    function withdrawAs(
        address _to,
        uint256 _shares,
        Option option,
        uint256 minAmountOut
    ) external;

    function withdrawAllAs(address _to, Option option) external;

    function withdrawAllAs(
        address _to,
        Option option,
        uint256 minAmountOut
    ) external;

    function depositAll(address _to) external returns (uint256 _shares);

    function deposit(address _to, uint256 _amount)
        external
        returns (uint256 _shares);

    function harvest() external;

    function balanceOfUnderlying(address user)
        external
        view
        returns (uint256 amount);

    function outstanding3CrvRewards() external view returns (uint256 total);

    function outstandingCvxRewards() external view returns (uint256 total);

    function outstandingCrvRewards() external view returns (uint256 total);

    function totalUnderlying() external view returns (uint256 total);

    function underlying() external view returns (address);

    function setPlatform(address _platform) external;

    function setPlatformFee(uint256 _fee) external;

    function setCallIncentive(uint256 _incentive) external;

    function setWithdrawalPenalty(uint256 _penalty) external;

    function setApprovals() external;
}

// Part: OpenZeppelin/[email protected]/Address

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// Part: OpenZeppelin/[email protected]/Context

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Ownable

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Part: OpenZeppelin/[email protected]/SafeERC20

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// Part: UnionBase

// Common variables and functions
contract UnionBase {
    address public constant CVXCRV_STAKING_CONTRACT =
        0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
    address public constant CURVE_CRV_ETH_POOL =
        0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
    address public constant CURVE_CVX_ETH_POOL =
        0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
    address public constant CURVE_CVXCRV_CRV_POOL =
        0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;

    address public constant CRV_TOKEN =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CVXCRV_TOKEN =
        0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address public constant CVX_TOKEN =
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    uint256 public constant CRVETH_ETH_INDEX = 0;
    uint256 public constant CRVETH_CRV_INDEX = 1;
    int128 public constant CVXCRV_CRV_INDEX = 0;
    int128 public constant CVXCRV_CVXCRV_INDEX = 1;
    uint256 public constant CVXETH_ETH_INDEX = 0;
    uint256 public constant CVXETH_CVX_INDEX = 1;

    IBasicRewards cvxCrvStaking = IBasicRewards(CVXCRV_STAKING_CONTRACT);
    ICurveV2Pool cvxEthSwap = ICurveV2Pool(CURVE_CVX_ETH_POOL);
    ICurveV2Pool crvEthSwap = ICurveV2Pool(CURVE_CRV_ETH_POOL);
    ICurveFactoryPool crvCvxCrvSwap = ICurveFactoryPool(CURVE_CVXCRV_CRV_POOL);

    /// @notice Swap CRV for cvxCRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @return amount of CRV obtained after the swap
    function _swapCrvToCvxCrv(uint256 amount, address recipient)
        internal
        returns (uint256)
    {
        return _crvToCvxCrv(amount, recipient, 0);
    }

    /// @notice Swap CRV for cvxCRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _swapCrvToCvxCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return _crvToCvxCrv(amount, recipient, minAmountOut);
    }

    /// @notice Swap CRV for cvxCRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _crvToCvxCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return
            crvCvxCrvSwap.exchange(
                CVXCRV_CRV_INDEX,
                CVXCRV_CVXCRV_INDEX,
                amount,
                minAmountOut,
                recipient
            );
    }

    /// @notice Swap cvxCRV for CRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @return amount of CRV obtained after the swap
    function _swapCvxCrvToCrv(uint256 amount, address recipient)
        internal
        returns (uint256)
    {
        return _cvxCrvToCrv(amount, recipient, 0);
    }

    /// @notice Swap cvxCRV for CRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _swapCvxCrvToCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return _cvxCrvToCrv(amount, recipient, minAmountOut);
    }

    /// @notice Swap cvxCRV for CRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _cvxCrvToCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return
            crvCvxCrvSwap.exchange(
                CVXCRV_CVXCRV_INDEX,
                CVXCRV_CRV_INDEX,
                amount,
                minAmountOut,
                recipient
            );
    }

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @return amount of ETH obtained after the swap
    function _swapCrvToEth(uint256 amount) internal returns (uint256) {
        return _crvToEth(amount, 0);
    }

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of ETH obtained after the swap
    function _swapCrvToEth(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return _crvToEth(amount, minAmountOut);
    }

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of ETH obtained after the swap
    function _crvToEth(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            crvEthSwap.exchange_underlying{value: 0}(
                CRVETH_CRV_INDEX,
                CRVETH_ETH_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @return amount of CRV obtained after the swap
    function _swapEthToCrv(uint256 amount) internal returns (uint256) {
        return _ethToCrv(amount, 0);
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _swapEthToCrv(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return _ethToCrv(amount, minAmountOut);
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _ethToCrv(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            crvEthSwap.exchange_underlying{value: amount}(
                CRVETH_ETH_INDEX,
                CRVETH_CRV_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @return amount of CRV obtained after the swap
    function _swapEthToCvx(uint256 amount) internal returns (uint256) {
        return _ethToCvx(amount, 0);
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _swapEthToCvx(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return _ethToCvx(amount, minAmountOut);
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _ethToCvx(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            cvxEthSwap.exchange_underlying{value: amount}(
                CVXETH_ETH_INDEX,
                CVXETH_CVX_INDEX,
                amount,
                minAmountOut
            );
    }

    modifier notToZeroAddress(address _to) {
        require(_to != address(0), "Invalid address!");
        _;
    }
}

// File: ExtraZaps.sol

contract ExtraZaps is Ownable, UnionBase {
    using SafeERC20 for IERC20;

    address public immutable vault;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    address private constant TRICRYPTO =
        0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address private constant TRIPOOL =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address private constant TRICRV =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address private constant BOOSTER =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address private constant CONVEX_TRIPOOL_TOKEN =
        0x30D9410ED1D5DA1F6C8391af5338C93ab8d4035C;
    address private constant CONVEX_TRIPOOL_REWARDS =
        0x689440f2Ff927E1f24c72F1087E1FAF471eCe1c8;
    address private constant CONVEX_LOCKER =
        0xD18140b4B819b895A3dba5442F959fA44994AF50;

    ICurveTriCrypto triCryptoSwap = ICurveTriCrypto(TRICRYPTO);
    ITriPool triPool = ITriPool(TRIPOOL);
    IBooster booster = IBooster(BOOSTER);
    IRewards triPoolRewards = IRewards(CONVEX_TRIPOOL_REWARDS);
    ICVXLocker locker = ICVXLocker(CONVEX_LOCKER);
    IMerkleDistributorV2 distributor;

    constructor(address _vault, address _distributor) {
        vault = _vault;
        distributor = IMerkleDistributorV2(_distributor);
    }

    function setApprovals() external {
        IERC20(TRICRV).safeApprove(BOOSTER, 0);
        IERC20(TRICRV).safeApprove(BOOSTER, type(uint256).max);

        IERC20(USDT).safeApprove(TRIPOOL, 0);
        IERC20(USDT).safeApprove(TRIPOOL, type(uint256).max);

        IERC20(CONVEX_TRIPOOL_TOKEN).safeApprove(CONVEX_TRIPOOL_REWARDS, 0);
        IERC20(CONVEX_TRIPOOL_TOKEN).safeApprove(
            CONVEX_TRIPOOL_REWARDS,
            type(uint256).max
        );

        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, type(uint256).max);

        IERC20(CVXCRV_TOKEN).safeApprove(vault, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(vault, type(uint256).max);

        IERC20(CVX).safeApprove(CONVEX_LOCKER, 0);
        IERC20(CVX).safeApprove(CONVEX_LOCKER, type(uint256).max);
    }

    /// @notice Retrieves user's uCRV and unstake to ETH
    /// @param amount - the amount of uCRV to unstake
    function _withdrawFromVaultAsEth(uint256 amount) internal {
        IERC20(vault).safeTransferFrom(msg.sender, address(this), amount);
        IUnionVault(vault).withdrawAllAs(
            address(this),
            IUnionVault.Option.ClaimAsETH
        );
    }

    /// @notice swap ETH to USDT via Curve's tricrypto
    /// @param amount - the amount of ETH to swap
    /// @param minAmountOut - the minimum amount expected
    function _swapEthToUsdt(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) internal {
        triCryptoSwap.exchange{value: amount}(
            2, // ETH
            0, // USDT
            amount,
            minAmountOut,
            true
        );
    }

    /// @notice Unstake from the Pounder to USDT
    /// @param amount - the amount of uCRV to unstake
    /// @param minAmountOut - the min expected amount of USDT to receive
    /// @param to - the adress that will receive the USDT
    /// @return amount of USDT obtained
    function claimFromVaultAsUsdt(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public notToZeroAddress(to) returns (uint256) {
        _withdrawFromVaultAsEth(amount);
        _swapEthToUsdt(address(this).balance, minAmountOut, to);
        uint256 _usdtAmount = IERC20(USDT).balanceOf(address(this));
        if (to != address(this)) {
            IERC20(USDT).safeTransfer(to, _usdtAmount);
        }
        return _usdtAmount;
    }

    /// @notice Claim from the distributor, unstake and returns USDT.
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    /// @param minAmountOut - the min expected amount of USDT to receive
    /// @param to - the adress that will receive the USDT
    /// @return amount of USDT obtained
    function claimFromDistributorAsUsdt(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 minAmountOut,
        address to
    ) external notToZeroAddress(to) returns (uint256) {
        distributor.claim(index, account, amount, merkleProof);
        return claimFromVaultAsUsdt(amount, minAmountOut, to);
    }

    /// @notice Unstake from the Pounder to stables and stake on 3pool convex for yield
    /// @param amount - amount of uCRV to unstake
    /// @param minAmountOut - minimum amount of 3CRV (NOT USDT!)
    /// @param to - address on behalf of which to stake
    function claimFromVaultAndStakeIn3PoolConvex(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public notToZeroAddress(to) {
        // claim as USDT
        uint256 _usdtAmount = claimFromVaultAsUsdt(amount, 0, address(this));
        // add USDT to Tripool
        triPool.add_liquidity([0, 0, _usdtAmount], minAmountOut);
        // deposit on Convex
        booster.depositAll(9, false);
        // stake on behalf of user
        triPoolRewards.stakeFor(
            to,
            IERC20(CONVEX_TRIPOOL_TOKEN).balanceOf(address(this))
        );
    }

    /// @notice Claim from the distributor, unstake and deposits in 3pool.
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    /// @param minAmountOut - minimum amount of 3CRV (NOT USDT!)
    /// @param to - address on behalf of which to stake
    function claimFromDistributorAndStakeIn3PoolConvex(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 minAmountOut,
        address to
    ) external notToZeroAddress(to) {
        distributor.claim(index, account, amount, merkleProof);
        claimFromVaultAndStakeIn3PoolConvex(amount, minAmountOut, to);
    }

    /// @notice Claim to any token via a univ2 router
    /// @notice Use at your own risk
    /// @param amount - amount of uCRV to unstake
    /// @param minAmountOut - min amount of output token expected
    /// @param router - address of the router to use. e.g. 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F for Sushi
    /// @param outputToken - address of the token to swap to
    /// @param to - address of the final recipient of the swapped tokens
    function claimFromVaultViaUniV2EthPair(
        uint256 amount,
        uint256 minAmountOut,
        address router,
        address outputToken,
        address to
    ) public notToZeroAddress(to) {
        require(router != address(0));
        _withdrawFromVaultAsEth(amount);
        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = outputToken;
        IUniV2Router(router).swapExactETHForTokens{
            value: address(this).balance
        }(minAmountOut, _path, to, block.timestamp + 60);
    }

    /// @notice Claim to any token via a univ2 router
    /// @notice Use at your own risk
    /// @param amount - amount of uCRV to unstake
    /// @param minAmountOut - min amount of output token expected
    /// @param router - address of the router to use. e.g. 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F for Sushi
    /// @param outputToken - address of the token to swap to
    /// @param to - address of the final recipient of the swapped tokens
    function claimFromDistributorViaUniV2EthPair(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 minAmountOut,
        address router,
        address outputToken,
        address to
    ) external notToZeroAddress(to) {
        distributor.claim(index, account, amount, merkleProof);
        claimFromVaultViaUniV2EthPair(
            amount,
            minAmountOut,
            router,
            outputToken,
            to
        );
    }

    /// @notice Unstake from the Pounder as CVX and locks it
    /// @param amount - amount of uCRV to unstake
    /// @param minAmountOut - min amount of CVX expected
    /// @param to - address to lock on behalf of
    function claimFromVaultAsCvxAndLock(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public notToZeroAddress(to) {
        IERC20(vault).safeTransferFrom(msg.sender, address(this), amount);
        IUnionVault(vault).withdrawAllAs(
            address(this),
            IUnionVault.Option.ClaimAsCVX,
            minAmountOut
        );
        locker.lock(to, IERC20(CVX).balanceOf(address(this)), 0);
    }

    /// @notice Claim from the distributor, unstake to CVX and lock.
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    /// @param minAmountOut - min amount of CVX expected
    /// @param to - address to lock on behalf of
    function claimFromDistributorAsCvxAndLock(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 minAmountOut,
        address to
    ) external notToZeroAddress(to) {
        distributor.claim(index, account, amount, merkleProof);
        claimFromVaultAsCvxAndLock(amount, minAmountOut, to);
    }

    /// @notice Deposit into the pounder from ETH
    /// @param minAmountOut - min amount of cvxCRV expected
    /// @param to - address to stake on behalf of
    function depositFromEth(uint256 minAmountOut, address to)
        external
        payable
        notToZeroAddress(to)
    {
        require(msg.value > 0, "cheap");
        _depositFromEth(msg.value, minAmountOut, to);
    }

    /// @notice Internal function to deposit ETH to the pounder
    /// @param amount - amount of ETH
    /// @param minAmountOut - min amount of cvxCRV expected
    /// @param to - address to stake on behalf of
    function _depositFromEth(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) internal {
        uint256 _crvAmount = _swapEthToCrv(amount);
        uint256 _cvxCrvAmount = _swapCrvToCvxCrv(
            _crvAmount,
            address(this),
            minAmountOut
        );
        IUnionVault(vault).deposit(to, _cvxCrvAmount);
    }

    /// @notice Deposit into the pounder from CRV
    /// @param minAmountOut - min amount of cvxCRV expected
    /// @param to - address to stake on behalf of
    function depositFromCrv(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external notToZeroAddress(to) {
        IERC20(CRV_TOKEN).safeTransferFrom(msg.sender, address(this), amount);
        uint256 _cvxCrvAmount = _swapCrvToCvxCrv(
            amount,
            address(this),
            minAmountOut
        );
        IUnionVault(vault).deposit(to, _cvxCrvAmount);
    }

    /// @notice Deposit into the pounder from any token via Uni interface
    /// @notice Use at your own risk
    /// @dev Zap contract needs approval for spending of inputToken
    /// @param amount - min amount of input token
    /// @param minAmountOut - min amount of cvxCRV expected
    /// @param router - address of the router to use. e.g. 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F for Sushi
    /// @param inputToken - address of the token to swap from, needs to have an ETH pair on router used
    /// @param to - address to stake on behalf of
    function depositViaUniV2EthPair(
        uint256 amount,
        uint256 minAmountOut,
        address router,
        address inputToken,
        address to
    ) external notToZeroAddress(to) {
        require(router != address(0));

        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), amount);
        address[] memory _path = new address[](2);
        _path[0] = inputToken;
        _path[1] = WETH;

        IERC20(inputToken).safeApprove(router, 0);
        IERC20(inputToken).safeApprove(router, amount);

        IUniV2Router(router).swapExactTokensForETH(
            amount,
            1,
            _path,
            address(this),
            block.timestamp + 1
        );
        _depositFromEth(address(this).balance, minAmountOut, to);
    }

    /// @notice Execute calls on behalf of contract
    /// (for instance to retrieve locked tokens)
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        return (success, result);
    }

    receive() external payable {}
}