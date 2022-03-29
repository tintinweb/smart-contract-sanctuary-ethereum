//SPDX-License-Identifier: None

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICurvePool {
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);

    function coins(uint256 i) external view returns (address);
}

interface ICurveRegistry {
    function find_pool_for_coins(address _from, address _to)
        external
        view
        returns (address);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);

    function get_coin_indices(
        address pool,
        address _from,
        address _to
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );
}

contract CurveRouter {
    using SafeERC20 for IERC20;

    uint256 private constant UINT_MAX = 2**256 - 1;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public owner;

    ICurvePool threePool;
    IERC20 threePoolToken;
    ICurveRegistry registry;
    ICurveRegistry factoryRegistry;

    constructor(
        address _threePool,
        address _tToken,
        address _registry,
        address _factoryRegistry
    ) {
        owner = msg.sender;
        threePool = ICurvePool(_threePool);
        threePoolToken = IERC20(_tToken);
        registry = ICurveRegistry(_registry);
        factoryRegistry = ICurveRegistry(_factoryRegistry);
    }

    function setOwner(address _owner) public {
        require(msg.sender == owner, "ONLY OWNER");
        require(_owner != address(0));
        owner = _owner;
    }

    function setThreePool(address _threePool) public {
        require(msg.sender == owner, "ONLY OWNER");
        threePool = ICurvePool(_threePool);
    }

    function setRegistry(address _registry) public {
        require(msg.sender == owner, "ONLY OWNER");
        registry = ICurveRegistry(_registry);
    }

    function setFactoryRegistry(address _factoryRegistry) public {
        require(msg.sender == owner, "ONLY OWNER");
        factoryRegistry = ICurveRegistry(_factoryRegistry);
    }

    function is_3pool_token(address _token) private pure returns (bool) {
        return _token == DAI || _token == USDC || _token == USDT;
    }

    function get_coin_id(address _token, address _pool)
        private
        view
        returns (int128)
    {
        address[8] memory underyling = registry.get_underlying_coins(_pool);

        int128 index = 0;
        for (uint256 i = 0; i < 8; ++i) {
            if (_token == underyling[i]) {
                return index;
            }
            index++;
        }

        underyling = factoryRegistry.get_underlying_coins(_pool);

        index = 0;
        for (uint256 i = 0; i < 8; ++i) {
            if (_token == underyling[i]) {
                return index;
            }
            index++;
        }

        return -1;
    }

    function find_coin_routes(address _from, address _to)
        external
        view
        returns (int128[4] memory, address[2] memory)
    {
        int128[4] memory coins;
        address[2] memory pools;

        if (!is_3pool_token(_from) && !is_3pool_token(_to)) {
            pools[0] = registry.find_pool_for_coins(_from, DAI);

            if (pools[0] == address(0)) {
                pools[0] = factoryRegistry.find_pool_for_coins(_from, DAI);
            }

            coins[0] = get_coin_id(_from, pools[0]);
            coins[1] = get_coin_id(DAI, pools[0]);

            pools[1] = registry.find_pool_for_coins(DAI, _to);

            if (pools[1] == address(0)) {
                pools[1] = factoryRegistry.find_pool_for_coins(DAI, _to);
            }

            coins[2] = get_coin_id(DAI, pools[1]);
            coins[3] = get_coin_id(_to, pools[1]);
        } else if (is_3pool_token(_from) && is_3pool_token(_to)) {
            pools[0] = address(threePool);
            coins[0] = get_coin_id(_from, pools[0]);
            coins[1] = get_coin_id(_to, pools[0]);
            coins[2] = coins[3] = -1;
        } else if (is_3pool_token(_from) || is_3pool_token(_to)) {
            pools[0] = registry.find_pool_for_coins(_from, _to);

            if (pools[0] == address(0)) {
                pools[0] = factoryRegistry.find_pool_for_coins(_from, _to);
            }

            coins[0] = get_coin_id(_from, pools[0]);
            coins[1] = get_coin_id(_to, pools[0]);
            coins[2] = coins[3] = -1;
        }

        return (coins, pools);
    }

    function get_dy_underlying_routed(
        int128[] memory ij,
        address[] memory path,
        uint256 dx
    ) external view returns (uint256) {
        require(
            ij.length > 0 &&
                path.length > 0 &&
                ij.length % 2 == 0 &&
                ij.length == path.length * 2
        );

        uint256 _dy = UINT_MAX;

        for (uint256 x = 0; x < path.length; x++) {
            ICurvePool pool = ICurvePool(path[x]);

            int128 i = ij[x * 2];
            int128 j = ij[x * 2 + 1];

            if (x == 0) {
                _dy = pool.get_dy_underlying(i, j, dx);
            } else {
                _dy = pool.get_dy_underlying(i, j, _dy);
            }
        }

        return _dy;
    }

    function exchange_underlying_routed(
        int128[] memory ij,
        address[] memory path,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256) {
        require(
            ij.length > 0 &&
                path.length > 0 &&
                ij.length % 2 == 0 &&
                ij.length == path.length * 2
        );

        uint256 dy = UINT_MAX;
        uint256 min_dy = UINT_MAX;

        for (uint256 x = 0; x < path.length; x++) {
            ICurvePool pool = ICurvePool(path[x]);

            int128 i = ij[x * 2];
            int128 j = ij[x * 2 + 1];

            address coin = address(0);

            if (is_meta_3pool(path[x]) && i > 0) {
                coin = threePool.coins(uint256(int256(i - 1)));
            } else {
                coin = pool.coins(uint256(int256(i)));
            }

            IERC20 sCoin = IERC20(coin);

            if (x == 0) {
                min_dy = pool.get_dy_underlying(i, j, _dx);
                sCoin.safeTransferFrom(msg.sender, address(this), _dx);
                sCoin.safeApprove(address(pool), _dx);
                dy = pool.exchange_underlying(i, j, _dx, min_dy);
            } else if (x == path.length - 1) {
                sCoin.safeApprove(address(pool), dy);
                dy = pool.exchange_underlying(i, j, dy, _min_dy, _receiver);
            } else {
                min_dy = pool.get_dy_underlying(i, j, dy);
                sCoin.safeApprove(address(pool), dy);
                dy = pool.exchange_underlying(i, j, dy, min_dy);
            }
        }

        return dy;
    }

    function is_meta_3pool(address _pool) private view returns (bool) {
        ICurvePool pool = ICurvePool(_pool);
        return pool.coins(1) == address(threePoolToken);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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