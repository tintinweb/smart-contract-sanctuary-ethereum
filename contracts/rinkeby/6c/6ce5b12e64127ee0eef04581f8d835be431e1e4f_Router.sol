// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IPoolFactory.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IPoolCallback.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IDebt.sol";
import "./interfaces/IWETH.sol";

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/base/Multicall.sol";

contract Router is IRouter, IPoolCallback, Multicall {
    fallback() external {}
    receive() payable external {}

    using SafeERC20 for IERC20;

    address public _factory;
    address public _wETH;
    address private _uniV3Factory;
    address private _uniV2Factory;
    address private _sushiFactory;
    uint32 private _tokenId = 0;

    struct tokenDate {
        address user;
        address poolAddress;
        uint32 positionId;
    }

    mapping(uint32 => tokenDate) public _tokenData;

    constructor(address factory, address uniV3Factory, address uniV2Factory, address sushiFactory, address wETH) {
        _factory = factory;
        _uniV3Factory = uniV3Factory;
        _uniV2Factory = uniV2Factory;
        _sushiFactory = sushiFactory;
        _wETH = wETH;
    }

    function poolV2Callback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external override payable {
        IPoolFactory qilin = IPoolFactory(_factory);
        require(
            qilin.pools(poolToken, oraclePool, reverse) == msg.sender,
            "poolV2Callback caller is not the pool contract"
        );

        if (poolToken == _wETH && address(this).balance >= amount) {
            IWETH wETH = IWETH(_wETH);
            wETH.deposit{value: amount}();
            wETH.transfer(msg.sender, amount);
        } else {
            IERC20(poolToken).safeTransferFrom(payer, msg.sender, amount);
        }
    }

    function poolV2RemoveCallback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external override {
        IPoolFactory qilin = IPoolFactory(_factory);
        require(
            qilin.pools(poolToken, oraclePool, reverse) == msg.sender,
            "poolV2Callback caller is not the pool contract"
        );

        IERC20(msg.sender).safeTransferFrom(payer, msg.sender, amount);
    }

    function poolV2BondsCallback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external override {
        address pool = IPoolFactory(_factory).pools(poolToken, oraclePool, reverse);
        require(
             pool == msg.sender,
            "poolV2BondsCallback caller is not the pool contract"
        );

        address debt = IPool(pool).debtToken();

        IERC20(debt).safeTransferFrom(payer, debt, amount);
    }

    function poolV2BondsCallbackFromDebt(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external override {
        address pool = IPoolFactory(_factory).pools(poolToken, oraclePool, reverse);
        address debt = IPool(pool).debtToken();
        require(
            debt == msg.sender,
            "poolV2BondsCallbackFromDebt caller is not the debt contract"
        );

        IERC20(debt).safeTransferFrom(payer, debt, amount);
    }

    function getPoolFromUni(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse
    ) public view returns (address) {
        address oraclePool;

        if (fee == 0) {
            oraclePool = IUniswapV2Factory(_uniV2Factory).getPair(tradeToken, poolToken);
        } else {
            oraclePool = IUniswapV3Factory(_uniV3Factory).getPool(tradeToken, poolToken, fee);
        }

        return IPoolFactory(_factory).pools(poolToken, oraclePool, reverse);
    }

    function getPoolFromSushi(
        address tradeToken,
        address poolToken,
        bool reverse
    ) public view returns (address) {
        address oraclePool = IUniswapV2Factory(_sushiFactory).getPair(tradeToken, poolToken);
        return IPoolFactory(_factory).pools(poolToken, oraclePool, reverse);
    }

    function createPoolFromUni(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse
    ) external override {
        IPoolFactory(_factory).createPoolFromUni(tradeToken, poolToken, fee, reverse);
    }

    function createPoolFromSushi(
        address tradeToken,
        address poolToken,
        bool reverse
    ) external override {
        IPoolFactory(_factory).createPoolFromSushi(tradeToken, poolToken, reverse);
    }

    function getLsBalance(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        address user
    ) external override view returns (uint256) {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        return IERC20(pool).balanceOf(user);
    }

    function getLsBalance2(
        address tradeToken,
        address poolToken,
        bool reverse,
        address user
    ) external override view returns (uint256) {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        return IERC20(pool).balanceOf(user);
    }

    function getLsPrice(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse
    ) external override view returns (uint256) {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        return IPool(pool).lsTokenPrice();
    }

    function getLsPrice2(
        address tradeToken,
        address poolToken,
        bool reverse
    ) external override view returns (uint256) {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        return IPool(pool).lsTokenPrice();
    }

    function addLiquidity(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 amount
    ) external override payable {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        IPool(pool).addLiquidity(msg.sender, amount);
    }

    function addLiquidity2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 amount
    ) external override payable {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        IPool(pool).addLiquidity(msg.sender, amount);
    }

    function removeLiquidity(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 lsAmount,
        uint256 bondsAmount,
        address receipt
    ) external override {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        IPool(pool).removeLiquidity(msg.sender, lsAmount, bondsAmount, receipt);
    }

    function removeLiquidity2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 lsAmount,
        uint256 bondsAmount,
        address receipt
    ) external override {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        IPool(pool).removeLiquidity(msg.sender, lsAmount, bondsAmount, receipt);
    }

    function openPosition(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external override payable {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        _tokenId++;
        uint32 positionId = IPool(pool).openPosition(
            msg.sender,
            direction,
            leverage,
            position
        );
        tokenDate memory tempTokenDate = tokenDate(
            msg.sender,
            pool,
            positionId
        );
        _tokenData[_tokenId] = tempTokenDate;
        emit TokenCreate(_tokenId, address(pool), msg.sender, positionId);
    }

    function openPosition2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external override payable {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        _tokenId++;
        uint32 positionId = IPool(pool).openPosition(
            msg.sender,
            direction,
            leverage,
            position
        );
        tokenDate memory tempTokenDate = tokenDate(
            msg.sender,
            pool,
            positionId
        );
        _tokenData[_tokenId] = tempTokenDate;
        emit TokenCreate(_tokenId, address(pool), msg.sender, positionId);
    }

    function addMargin(uint32 tokenId, uint256 margin) external override payable {
        tokenDate memory tempTokenDate = _tokenData[tokenId];
        require(
            tempTokenDate.user == msg.sender,
            "token owner not match msg.sender"
        );
        IPool(tempTokenDate.poolAddress).addMargin(
            msg.sender,
            tempTokenDate.positionId,
            margin
        );
    }

    function closePosition(uint32 tokenId, address receipt) external override {
        tokenDate memory tempTokenDate = _tokenData[tokenId];
        require(
            tempTokenDate.user == msg.sender,
            "token owner not match msg.sender"
        );
        IPool(tempTokenDate.poolAddress).closePosition(
            receipt,
            tempTokenDate.positionId
        );
    }

    function liquidate(uint32 tokenId, address receipt) external override {
        tokenDate memory tempTokenDate = _tokenData[tokenId];
        require(tempTokenDate.user != address(0), "tokenId does not exist");
        IPool(tempTokenDate.poolAddress).liquidate(
            msg.sender,
            tempTokenDate.positionId,
            receipt
        );
    }

    function liquidateByPool(address poolAddress, uint32 positionId, address receipt) external override {
        IPool(poolAddress).liquidate(msg.sender, positionId, receipt);
    }

    function withdrawERC20(address poolToken) external override {
        IERC20 erc20 = IERC20(poolToken);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance > 0, "balance of router must > 0");
        erc20.safeTransfer(msg.sender, balance);
    }

    function withdrawETH() external override {
        uint256 balance = IERC20(_wETH).balanceOf(address(this));
        require(balance > 0, "balance of router must > 0");
        IWETH(_wETH).withdraw(balance);
        (bool success, ) = msg.sender.call{value: balance}(new bytes(0));
        require(success, "ETH transfer failed");
    }

    function repayLoan(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 amount,
        address receipt
    ) external override payable {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        address debtToken = IPool(pool).debtToken();
        IDebt(debtToken).repayLoan(msg.sender, receipt, amount);
    }

    function repayLoan2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 amount,
        address receipt
    ) external override payable {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        address debtToken = IPool(pool).debtToken();
        IDebt(debtToken).repayLoan(msg.sender, receipt, amount);
    }

    function exit(uint32 tokenId, address receipt) external override {
        tokenDate memory tempTokenDate = _tokenData[tokenId];
        require(
            tempTokenDate.user == msg.sender,
            "token owner not match msg.sender"
        );
        IPool(tempTokenDate.poolAddress).exit(
            receipt,
            tempTokenDate.positionId
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IRouter {
    function createPoolFromUni(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse
    ) external;

    function createPoolFromSushi(
        address tradeToken,
        address poolToken,
        bool reverse
    ) external;

    function getLsBalance(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        address user
    ) external view returns (uint256);

    function getLsBalance2(
        address tradeToken,
        address poolToken,
        bool reverse,
        address user
    ) external view returns (uint256);

    function getLsPrice(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse
    ) external view returns (uint256);

    function getLsPrice2(
        address tradeToken,
        address poolToken,
        bool reverse
    ) external view returns (uint256);

    function addLiquidity(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 amount
    ) external payable;

    function addLiquidity2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 amount
    ) external payable;

    function removeLiquidity(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 lsAmount,
        uint256 bondsAmount,
        address receipt
    ) external;

    function removeLiquidity2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 lsAmount,
        uint256 bondsAmount,
        address receipt
    ) external;

    function openPosition(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external payable;

    function openPosition2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external payable;

    function addMargin(uint32 tokenId, uint256 margin) external payable;

    function closePosition(uint32 tokenId, address receipt) external;

    function liquidate(uint32 tokenId, address receipt) external;

    function liquidateByPool(address poolAddress, uint32 positionId, address receipt) external;

    function withdrawERC20(address poolToken) external;

    function withdrawETH() external;

    function repayLoan(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 amount,
        address receipt
    ) external payable;

    function repayLoan2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 amount,
        address receipt
    ) external payable;

    function exit(uint32 tokenId, address receipt) external;

    event TokenCreate(uint32 tokenId, address pool, address sender, uint32 positionId);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IPoolFactory {
    function createPoolFromUni(address tradeToken, address poolToken, uint24 fee, bool reverse) external;

    function createPoolFromSushi(address tradeToken, address poolToken, bool reverse) external;

    function pools(address poolToken, address oraclePool, bool reverse) external view returns (address pool);

    event CreatePoolFromUni(
        address tradeToken,
        address poolToken,
        address uniPool,
        address pool,
        address debt,
        string tradePair,
        uint24 fee,
        bool reverse);

    event CreatePoolFromSushi(
        address tradeToken,
        address poolToken,
        address sushiPool,
        address pool,
        address debt,
        string tradePair,
        bool reverse);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IPoolCallback {
    function poolV2Callback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external payable;

    function poolV2RemoveCallback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external;

    function poolV2BondsCallback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external;

    function poolV2BondsCallbackFromDebt(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IPool {
    struct Position {
        uint256 openPrice;
        uint256 openBlock;
        uint256 margin;
        uint256 size;
        uint256 openRebase;
        address account;
        uint8 direction;
    }

    function _positions(uint32 positionId)
        external
        view
        returns (
            uint256 openPrice,
            uint256 openBlock,
            uint256 margin,
            uint256 size,
            uint256 openRebase,
            address account,
            uint8 direction
        );

    function debtToken() external view returns (address);

    function lsTokenPrice() external view returns (uint256);

    function addLiquidity(address user, uint256 amount) external;

    function removeLiquidity(address user, uint256 lsAmount, uint256 bondsAmount, address receipt) external;

    function openPosition(
        address user,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external returns (uint32);

    function addMargin(
        address user,
        uint32 positionId,
        uint256 margin
    ) external;

    function closePosition(
        address receipt,
        uint32 positionId
    ) external;

    function liquidate(
        address user,
        uint32 positionId,
        address receipt
    ) external;

    function exit(
        address receipt,
        uint32 positionId
    ) external;

    event MintLiquidity(uint256 amount);

    event AddLiquidity(
        address indexed sender,
        uint256 amount,
        uint256 lsAmount,
        uint256 bonds
    );

    event RemoveLiquidity(
        address indexed sender,
        uint256 amount,
        uint256 lsAmount,
        uint256 bondsRequired
    );

    event OpenPosition(
        address indexed sender,
        uint256 openPrice,
        uint256 openRebase,
        uint8 direction,
        uint16 level,
        uint256 margin,
        uint256 size,
        uint32 positionId
    );

    event AddMargin(
        address indexed sender,
        uint256 margin,
        uint32 positionId
    );

    event ClosePosition(
        address indexed receipt,
        uint256 closePrice,
        uint256 serviceFee,
        uint256 fundingFee,
        uint256 pnl,
        uint32  positionId,
        bool isProfit,
        int256 debtChange
    );

    event Liquidate(
        address indexed sender,
        uint32 positionID,
        uint256 liqPrice,
        uint256 serviceFee,
        uint256 fundingFee,
        uint256 liqReward,
        uint256 pnl,
        bool isProfit,
        uint256 debtRepay
    );

    event Rebase(uint256 rebaseAccumulatedLong, uint256 rebaseAccumulatedShort);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IDebt {

    function owner() external view returns (address);

    function issueBonds(address recipient, uint256 amount) external;

    function burnBonds(uint256 amount) external;

    function repayLoan(address payer, address recipient, uint256 amount) external;

    function totalDebt() external view returns (uint256);

    function bondsLeft() external view returns (uint256);

    event RepayLoan(
        address indexed receipt,
        uint256 bondsTokenAmount,
        uint256 poolTokenAmount
    );
}