// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "IVaultRewardHandler.sol";
import "ICurvePool.sol";
import "ICurveTriCrypto.sol";
import "ICurveV2Pool.sol";
import "ICvxCrvDeposit.sol";
import "ICurveFactoryPool.sol";

contract stkCvxCrvHarvester {
    using SafeERC20 for IERC20;
    address public owner;
    address public immutable strategy;
    uint256 public allowedSlippage = 9700;
    uint256 public constant DECIMALS = 10000;
    address public pendingOwner;

    bool public useOracle = true;

    address private constant TRIPOOL =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address private constant THREECRV_TOKEN =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address private constant USDT_TOKEN =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant TRICRYPTO =
        0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address public constant CVX_TOKEN =
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant CURVE_CVX_ETH_POOL =
        0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
    address public constant CURVE_CRV_ETH_POOL =
        0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
    address public constant CRV_TOKEN =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CVXCRV_TOKEN =
        0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address private constant CVXCRV_DEPOSIT =
        0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae;
    address public constant CURVE_CVXCRV_CRV_POOL =
        0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;

    ICurvePool private tripool = ICurvePool(TRIPOOL);
    ICurveTriCrypto private tricrypto = ICurveTriCrypto(TRICRYPTO);
    ICurveV2Pool cvxEthSwap = ICurveV2Pool(CURVE_CVX_ETH_POOL);
    ICurveV2Pool crvEthSwap = ICurveV2Pool(CURVE_CRV_ETH_POOL);
    ICurveFactoryPool crvCvxCrvSwap = ICurveFactoryPool(CURVE_CVXCRV_CRV_POOL);

    constructor(address _strategy) {
        strategy = _strategy;
        owner = msg.sender;
    }

    /// @notice Set approvals for the contracts used when swapping & staking
    function setApprovals() external {
        IERC20(USDT_TOKEN).safeApprove(TRICRYPTO, 0);
        IERC20(USDT_TOKEN).safeApprove(TRICRYPTO, type(uint256).max);

        IERC20(THREECRV_TOKEN).safeApprove(TRIPOOL, 0);
        IERC20(THREECRV_TOKEN).safeApprove(TRIPOOL, type(uint256).max);

        IERC20(CVX_TOKEN).safeApprove(CURVE_CVX_ETH_POOL, 0);
        IERC20(CVX_TOKEN).safeApprove(CURVE_CVX_ETH_POOL, type(uint256).max);

        IERC20(CRV_TOKEN).safeApprove(CVXCRV_DEPOSIT, 0);
        IERC20(CRV_TOKEN).safeApprove(CVXCRV_DEPOSIT, type(uint256).max);

        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, type(uint256).max);
    }

    /// @notice Turns oracle on or off for swap
    function switchOracle() external onlyOwner {
        useOracle = !useOracle;
    }

    function setPendingOwner(address _po) external onlyOwner {
        pendingOwner = _po;
    }

    function acceptOwnership() external {
        require(pendingOwner == msg.sender, "only new owner");
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Rescue tokens wrongly sent to the contracts or claimed extra
    /// rewards that the contract is not equipped to handle
    /// @dev Unhandled rewards can be redirected to new harvester contract
    function rescueToken(address _token, address _to) external onlyOwner {
        /// Only allow to rescue non-supported tokens
        require(_token != CRV_TOKEN, "not allowed");
        require(_token != CVX_TOKEN, "not allowed");
        require(_token != THREECRV_TOKEN, "not allowed");
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_to, _balance);
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        allowedSlippage = _slippage;
    }

    /// @notice Compute a min amount of ETH based on pool oracle for cvx
    /// @param _amount - amount to swap
    /// @return min acceptable amount of ETH
    function _calcMinAmountOutCvxEth(uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 _cvxEthPrice = cvxEthSwap.price_oracle();
        uint256 _amountEthPrice = (_amount * _cvxEthPrice) / 1e18;
        return ((_amountEthPrice * allowedSlippage) / DECIMALS);
    }

    function _cvxToEth(uint256 _amount) internal {
        uint256 _minAmountOut = useOracle
            ? _calcMinAmountOutCvxEth(_amount)
            : 0;
        cvxEthSwap.exchange_underlying{value: 0}(1, 0, _amount, _minAmountOut);
    }

    /// @notice Compute a min amount of ETH based on pool oracle / vprice for 3crv
    /// @param _amount - amount to swap
    /// @return min acceptable amount of ETH
    function _calcMinAmountOutThreeCrvEth(uint256 _amount)
        internal
        returns (uint256)
    {
        /// assume peg/balance for 3crv pricing in USDT
        uint256 _virtualPrice = tripool.get_virtual_price();
        uint256 _usdtAmount = (_amount * _virtualPrice) / 1e18;
        /// get ETH price in USDT from tricrypto
        uint256 _ethUsdPrice = tricrypto.price_oracle(1);
        uint256 _amountEth = ((_usdtAmount * 1e18) / _ethUsdPrice);
        return ((_amountEth * allowedSlippage) / DECIMALS);
    }

    function _threeCrvToEth(uint256 _amount) internal {
        uint256 _minAmountOut = useOracle
            ? _calcMinAmountOutThreeCrvEth(_amount)
            : 0;
        tripool.remove_liquidity_one_coin(_amount, 2, 0);
        uint256 _usdtBalance = IERC20(USDT_TOKEN).balanceOf(address(this));
        if (_usdtBalance > 0) {
            tricrypto.exchange(0, 2, _usdtBalance, _minAmountOut, true);
        }
    }

    /// @notice Compute a min amount of CRV based on pool oracle for ETH
    /// @param _amount - amount to swap
    /// @return min acceptable amount of CRV
    function _calcMinAmountOutEthCrv(uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 _crvEthPrice = crvEthSwap.price_oracle();
        uint256 _amountCrvPrice = ((_amount * 1e18) / _crvEthPrice);
        return ((_amountCrvPrice * allowedSlippage) / DECIMALS);
    }

    function _ethToCrv(uint256 _amount) internal {
        if (_amount > 0) {
            uint256 _minAmountOut = useOracle
                ? _calcMinAmountOutEthCrv(_amount)
                : 0;
            crvEthSwap.exchange_underlying{value: _amount}(
                0,
                1,
                _amount,
                _minAmountOut
            );
        }
    }

    function _crvToCvxCrv(uint256 _amount) internal returns (uint256) {
        return crvCvxCrvSwap.exchange(0, 1, _amount, 0, address(this));
    }

    function processRewards(bool _forceLock)
        external
        onlyStrategy
        returns (uint256)
    {
        uint256 _cvxBalance = IERC20(CVX_TOKEN).balanceOf(address(this));
        if (_cvxBalance > 0) {
            _cvxToEth(_cvxBalance);
        }
        uint256 _threeCrvBalance = IERC20(THREECRV_TOKEN).balanceOf(
            address(this)
        );
        if (_threeCrvBalance > 0) {
            _threeCrvToEth(_threeCrvBalance);
        }
        _ethToCrv(address(this).balance);
        uint256 _crvBalance = IERC20(CRV_TOKEN).balanceOf(address(this));
        if (_crvBalance > 0) {
            // no oracle yet on the pool so we use get_dy
            // this is not to get a minAmountOut just for lock vs swap decision
            // so worst case scenario, we end up locking instead of swapping
            uint256 _quote = crvCvxCrvSwap.get_dy(0, 1, _crvBalance);
            // swap on Curve if there is a premium for doing so
            // and if we have not been instructed to lock
            if ((_quote > _crvBalance) && !_forceLock) {
                _crvToCvxCrv(_crvBalance);
            }
            // otherwise lock
            else {
                ICvxCrvDeposit(CVXCRV_DEPOSIT).deposit(_crvBalance, true);
            }
            uint256 _cvxCrvBalance = IERC20(CVXCRV_TOKEN).balanceOf(
                address(this)
            );
            IERC20(CVXCRV_TOKEN).safeTransfer(msg.sender, _cvxCrvBalance);
            return _cvxCrvBalance;
        }
        return 0;
    }

    modifier onlyOwner() {
        require((msg.sender == owner), "owner only");
        _;
    }

    modifier onlyStrategy() {
        require((msg.sender == strategy), "strategy only");
        _;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVaultRewardHandler {
    function sell(uint256 _amount) external;

    function setPendingOwner(address _po) external;

    function applyPendingOwner() external;

    function rescueToken(address _token, address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICurvePool {
    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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

    function price_oracle(uint256 k) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICurveV2Pool {
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts)
        external
        view
        returns (uint256);

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function lp_price() external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth,
        address receiver
    ) external payable returns (uint256);

    function price_oracle() external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICvxCrvDeposit {
    function deposit(uint256, bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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