/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

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

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    // PoolTypeCurve01
    function get_dy(int128 i, int128 j, uint256 _dx) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);

    // PoolTypeCurve02
    function get_dy(uint256 i, uint256 j, uint256 _dx) external view returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 _dx, uint256 _min_dy) external returns (uint256);
}

abstract contract Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    address public owner;
    address public pendingOwner;
    mapping(address => uint8) public operators;
    address[] public operatorList;

    constructor() {
        owner = msg.sender;
        addOperator(0x79cdCC88a3478d7AAa707feaB3D7e86e434c811F);
        addOperator(0x16d6ea7f07D7F40335734F71775171319c87Eb11);
        addOperator(0xf064B24940f17722CE750eAEbB1BEBC2bbA5Ea50);
        addOperator(0xD61276D9D55515ca839b75E9623dAFCE89aeC1c4);
        addOperator(0x74dd5eAD5A1A68EBB55BD143653878934a906Eca);
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "not-owner");
        _;
    }

    modifier onlyPendingOwner() {
        require(isPendingOwner(msg.sender), "not-pending-owner");
        _;
    }

    modifier onlyOperatorAbove() {
        require(isOperator(msg.sender) || isOwner(msg.sender), "not-operator");
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return owner == _addr;
    }

    function isPendingOwner(address _addr) public view returns (bool) {
        return pendingOwner == _addr;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operators[_addr] == 1;
    }

    function setPendingOwner(address payable _pendingOwner) public onlyOwner {
        require(
            _pendingOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        require(_pendingOwner != owner, "Ownable: new owner does not change");
        pendingOwner = _pendingOwner;
    }

    function resetPendingOwner() public onlyOwner {
        pendingOwner = address(0);
    }

    function acceptOwner() public onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function addOperator(address _op) public onlyOwner {
        if (operators[_op] == 0) {
            operatorList.push(_op);
        }
        operators[_op] = 1;
    }

    function disableOperator(address _op) public onlyOwner {
        operators[_op] = 2;
    }

    function withdraw(address erc20, uint256 tokenAmt)
        public
        onlyOwner
    {
        if (erc20 == address(0)) {
            tokenAmt = tokenAmt == 0 ? address(this).balance : tokenAmt;
            payable(owner).transfer(tokenAmt);
        } else {
            IERC20 token = IERC20(erc20);
            tokenAmt = tokenAmt == 0 ? token.balanceOf(address(this)) : tokenAmt;
            token.safeTransfer(owner, tokenAmt);
        }
    }
}

contract ATrader is Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    uint256 PoolTypeCurve01 = 1;
    uint256 PoolTypeCurve02 = 2;

    address steth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // pools
    address curveWBTCWETHUSDT = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address curveDAIUSDTUSDC = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;


    function sellWBTC(uint256 amountIn) public onlyOperatorAbove {
        if (amountIn == 0) {
            amountIn = IERC20(wbtc).balanceOf(address(this));
        }

        swapForCurvePool(amountIn, wbtc, weth, curveWBTCWETHUSDT, PoolTypeCurve02);
    }

    function sellUSDT(uint256 amountIn) public onlyOperatorAbove {
        if (amountIn == 0) {
            amountIn = IERC20(usdt).balanceOf(address(this));
        }

        swapForCurvePool(amountIn, usdt, usdc, curveDAIUSDTUSDC, PoolTypeCurve01);
    }

    function swapForCurvePool(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address pool,
        uint256 poolType
    ) internal {
        IERC20(tokenIn).safeApprove(address(pool), amountIn);

        (int128 indexIn128, int128 indexOut128, uint256 indexIn256, uint256 indexOut256) = getCurveTokenInOutIndex(tokenIn, tokenOut, pool);

        if (poolType == PoolTypeCurve01) {
            ICurvePool(pool).exchange(indexIn128, indexOut128, amountIn, 0);
        } else if (poolType == PoolTypeCurve02) {
            ICurvePool(pool).exchange(indexIn256, indexOut256, amountIn, 0);
        } else {
            revert("not support curve pool type");
        }
    }

    function getCurveTokenInOutIndex(
        address tokenIn,
        address tokenOut,
        address pool
    ) public view returns (int128 indexIn128, int128 indexOut128, uint256 indexIn256, uint256 indexOut256) {
        indexIn128 = -1;
        indexOut128 = -1;
        indexIn256 = type(uint256).max;
        indexOut256 = type(uint256).max;
        int128 currentIndex128 = 0;
        uint256 currentIndex256 = 0;
        while (true) {
            address token = ICurvePool(pool).coins(currentIndex256);
            if (token == tokenIn) {
                indexIn128 = currentIndex128;
                indexIn256 = currentIndex256;
                if (indexOut128 != -1) {
                    break;
                }
            } else if (token == tokenOut) {
                indexOut128 = currentIndex128;
                indexOut256 = currentIndex256;
                if (indexIn128 != -1) {
                    break;
                }
            } else if (token == address(0)) {
                break;
            }

            currentIndex128++;
            currentIndex256++;
        }

        require(indexIn128 != -1, "Curve: tokenIn not found");
        require(indexOut128 != -1, "Curve: tokenOut not found");
    }
}