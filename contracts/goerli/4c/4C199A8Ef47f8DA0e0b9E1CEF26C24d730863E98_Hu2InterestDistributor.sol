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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapV2Pair } from "./interfaces/external/uniswap/v2/IUniswapV2Pair.sol";
import { IHu2Token } from "./interfaces/IHu2Token.sol";
import { IHu2InterestDistributor } from "./interfaces/IHu2InterestDistributor.sol";


/**
 * @title Hu2InterestDistributor
 * @author Hysland Finance
 * @notice Distributes interest earned from reinvestments into Uniswap V2 pools.
 *
 * Each Uniswap V2 pool contains two tokens. This contract rebases them at the same time then syncs the reserves. It works whether the tokens are hu2 tokens or not, or whatever interest bearing protocol they use.
 *
 * A single pool can be rebased via [`distributeInterestToPool()`](#distributeinteresttopool). Multiple pools can be rebased in one call via [`distributeInterestToPools()`](#distributeinteresttopools).
 */
contract Hu2InterestDistributor is IHu2InterestDistributor {

    /***************************************
    STATE VARIABLES
    ***************************************/

    // store locally. saves gas
    struct UniswapV2PoolData {
        address token0;
        address token1;
    }
    mapping(address => UniswapV2PoolData) internal _poolDatas;

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Distributes interest to a Uniswap V2 pool.
     * @param pool The address of the Uniswap V2 pool to distribute interest to.
     */
    function distributeInterestToPool(address pool) external override {
        (address token0, address token1) = _getTokens(pool);
        // for each token distribute interest to pool
        // revert usually means the token is not a Hu2Token and has no matching sighash
        // use low level calls to allow revert
        bytes memory data = abi.encodeWithSelector(IHu2Token(token0).distributeInterestToPool.selector, pool);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success1, ) = token0.call(data);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success2, ) = token1.call(data);
        if(success1 || success2) {
            // sync pool to new balances
            IUniswapV2Pair(pool).sync();
            emit InterestDistributed(pool);
        }
    }

    /**
     * @notice Distributes interest to multiple Uniswap V2 pools.
     * @param pools The list of Uniswap V2 pools to distribute interest to.
     */
    function distributeInterestToPools(address[] calldata pools) external override {
        // loop over pools
        for(uint256 i = 0; i < pools.length; i++) {
            address pool = pools[i];
            (address token0, address token1) = _getTokens(pool);
            // for each token distribute interest to pool
            // revert usually means the token is not a Hu2Token and has no matching sighash
            // use low level calls to allow revert
            bytes memory data = abi.encodeWithSelector(IHu2Token(token0).distributeInterestToPool.selector, pool);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success1, ) = token0.call(data);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success2, ) = token1.call(data);
            if(success1 || success2) {
                // sync pool to new balances
                IUniswapV2Pair(pool).sync();
                emit InterestDistributed(pool);
            }
        }
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Gets the tokens in a Uniswap V2 pool.
     * @param pool The address of the pool to query.
     * @return token0 The pool's token0.
     * @return token1 The pool's token1.
     */
    function _getTokens(address pool) internal returns (address token0, address token1) {
        // uses cache for gas savings
        // try fetch from cache
        UniswapV2PoolData memory data = _poolDatas[pool];
        if(data.token0 != address(0x0)) return (data.token0, data.token1);
        // external calls
        token0 = IUniswapV2Pair(pool).token0();
        token1 = IUniswapV2Pair(pool).token1();
        // write to cache
        _poolDatas[pool] = UniswapV2PoolData({
            token0: token0,
            token1: token1
        });
        return (token0, token1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IHu2InterestDistributor
 * @author Hysland Finance
 * @notice Distributes interest earned from reinvestments into Uniswap V2 pools.
 *
 * Each Uniswap V2 pool contains two tokens. This contract rebases them at the same time then syncs the reserves. It works whether the tokens are hu2 tokens or not, or whatever interest bearing protocol they use.
 *
 * A single pool can be rebased via [`distributeInterestToPool()`](#distributeinteresttopool). Multiple pools can be rebased in one call via [`distributeInterestToPools()`](#distributeinteresttopools).
 */
interface IHu2InterestDistributor {

    /***************************************
    EVENTS FUNCTIONS
    ***************************************/

    /// @notice Emitted when interest is distributed to a pool.
    event InterestDistributed(address indexed pool);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Distributes interest to a Uniswap V2 pool.
     * @param pool The address of the Uniswap V2 pool to distribute interest to.
     */
    function distributeInterestToPool(address pool) external;

    /**
     * @notice Distributes interest to multiple Uniswap V2 pools.
     * @param pools The list of Uniswap V2 pools to distribute interest to.
     */
    function distributeInterestToPools(address[] calldata pools) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IHwTokenBase } from "./IHwTokenBase.sol";


/**
 * @title IHu2Token
 * @author Hysland Finance
 * @notice An interest bearing token designed to be used in Uniswap V2 pools.
 *
 * Most liquidity pools were designed to work with "standard" ERC20 tokens. The vault tokens of some interest bearing protocols may not work well with some liquidity pools. Hyswap vault wrappers are ERC20 tokens around these vaults that help them work better in liquidity pools. Liquidity providers of Hyswap pools will earn from both swap fees and interest from vaults.
 *
 * ```
 * ------------------------
 * | hyswap wrapper token | eg hu2yvDAI
 * | -------------------- |
 * | |   vault token    | | eg yvDAI
 * | | ---------------- | |
 * | | |  base token  | | | eg DAI
 * | | ---------------- | |
 * | -------------------- |
 * ------------------------
 * ```
 *
 * This is the base type of hwTokens that are designed for use in Uniswap V2, called Hyswap Uniswap V2 Vault Wrappers.
 *
 * Interest will accrue over time. This will increase each accounts [`interestOf()`](#interestof) and [`balancePlusInterestOf()`](#balanceplusinterestof) but not their `balanceOf()`. Users can move this amount to their `balanceOf()` via [`accrueInterest()`](#accrueinterest). The [`interestDistributor()`](#interestdistributor) can accrue the interest of a Uniswap V2 pool via [`distributeInterestToPool()`](#distributeinteresttopool). For accounting purposes, [`accrueInterestMultiple()`](#accrueinterestmultiple) and `transfer()` will also accrue interest, but this amount won't be added to the accounts `balanceOf()` until a call to [`accrueInterest()`](#accrueinterest) or [`distributeInterestToPool()`](#distributeinteresttopool).
 *
 * Most users won't hold this token and can largely ignore that it exists. If you see it in a Uniswap V2 pool, you can think of it as the base token. Integrators should perform the routing for you. Regular users should hold the base token for regular use, the vault token to earn interest, or the LP token to earn interest plus swap fees. High frequency traders may hold the Hu2Token for reduced gas fees.
 *
 * A portion of the interest earned may be redirected to the Hyswap treasury and integrators. The percentage can be viewed via [`interestShare()`](#interestshare) and the receiver can be viewed via [`treasury()`](#treasury).
 */
interface IHu2Token is IHwTokenBase {

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the amount of interest claimable by `account`.
     * @param account The account to query interest of.
     * @return interest The account's accrued interest.
     */
    function interestOf(address account) external view returns (uint256 interest);

    /**
     * @notice Returns the balance of an account after adding interest.
     * @param account The account to query interest of.
     * @return balance The account's new balance.
     */
    function balancePlusInterestOf(address account) external view returns (uint256 balance);

    /**
     * @notice The percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision.
     * @return interestShare_ The interest share with 18 decimals of precision.
     */
    function interestShare() external view returns (uint256 interestShare_);

    /**
     * @notice The address to receive the interest not directed towards holders. Can be modified in each hu2token instance.
     * @return treasury_ The treasury address.
     */
    function treasury() external view returns (address treasury_);

    /**
     * @notice The address of the [`Hu2InterestDistributor`](./IHu2InterestDistributor).
     * @return distributor_ The distributor.
     */
    function interestDistributor() external view returns (address distributor_);

    /***************************************
    INTEREST ACCRUAL FUNCTIONS
    ***************************************/

    /**
     * @notice Accrues the interest owed to `msg.sender` and adds it to their balance.
     */
    function accrueInterest() external;

    /**
     * @notice Accrues the interest owed to multiple accounts and adds it to their unpaid interest.
     * @param accounts The list of accouunts to accrue interest for.
     */
    function accrueInterestMultiple(address[] calldata accounts) external;

    /**
     * @notice Distributes interest earned by a Uniswap V2 pool to its reserves.
     * Can only be called by the [`Hu2InterestDistributor`](./IHu2InterestDistributor).
     * @param pool The address of the Uniswap V2 pool to distribute interest to.
     */
    function distributeInterestToPool(address pool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IHwTokenBase
 * @author Hysland Finance
 * @notice A custom implementation of an ERC20 token with the metadata and permit extensions.
 *
 * This was forked from OpenZeppelin's implementation with a few key differences:
 * - It uses an initialzer instead of a constructor, allowing for easier use in factory patterns.
 * - State variables are declared as internal instead of private, allowing use by child contracts.
 * - Minor efficiency improvements. Removed zero address checks, context, shorter revert strings.
 */
interface IHwTokenBase {

    /***************************************
    EVENTS
    ***************************************/

    /**
     * @notice Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to [`approve()`](#approve). `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the name of the token.
     * @return name_ The name of the token.
     */
    function name() external view returns (string memory name_);

    /**
     * @notice Returns the symbol of the token.
     * @return symbol_ The symbol of the token.
     */
    function symbol() external view returns (string memory symbol_);

    /**
     * @notice Returns the decimals places of the token.
     * @return decimals_ The decimals of the token.
     */
    function decimals() external view returns (uint8 decimals_);

    /**
     * @notice Returns the amount of tokens in existence.
     * @return supply The amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 supply);

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param account The account to query balance of.
     * @return balance The account's balance.
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice Returns the remaining number of tokens that `spender` is
     * allowed to spend on behalf of `owner` through [`transferFrom()`](#transferfrom). This is
     * zero by default.
     *
     * This value changes when [`approve()`](#approve), [`transferFrom()`](#transferfrom),
     * or [`permit()`](#permit) are called.
     *
     * @param owner The owner of tokens.
     * @param spender The spender of tokens.
     * @return allowance_ The amount of `owner`'s tokens that `spender` can spend.
     */
    function allowance(address owner, address spender) external view returns (uint256 allowance_);

    /**
     * @notice Returns the current nonce for `owner`. This value must be included whenever a signature is generated for [`permit()`](#permit).
     * @param owner The owner of tokens.
     * @return nonce_ The owner's nonce.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for [`permit()`](#permit), as defined by EIP712.
     * @return separator The domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 separator);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `amount`.
     *
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     * @return success True on success, false otherwise.
     */
    function transfer(address recipient, uint256 amount) external returns (bool success);

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     *
     * @param sender The sender of the tokens.
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     * @return success True on success, false otherwise.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
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
     * Emits an `Approval` event.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param amount The amount of tokens to allow to spend.
     * @return success True on success, false otherwise.
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to [`approve()`](#approve) that can be used as a mitigation for
     * problems described in [`approve()`](#approve).
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param addedValue The amount to increase allowance.
     * @return success True on success, false otherwise.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool success);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to [`approve()`](#approve) that can be used as a mitigation for
     * problems described in [`approve()`](#approve).
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param subtractedValue The amount to decrease allowance.
     * @return success True on success, false otherwise.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool success);

    /**
     * @notice Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues [`approve()`](#approve) has related to transaction
     * ordering also apply here.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see [`nonces()`](#nonces)).
     *
     * For more information on the signature format, see
     * [EIP2612](https://eips.ethereum.org/EIPS/eip-2612#specification).
     *
     * @param owner The owner of the tokens.
     * @param spender The spender of the tokens.
     * @param value The amount to approve.
     * @param deadline The timestamp that `permit()` must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}