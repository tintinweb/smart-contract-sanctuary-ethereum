/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File contracts/interfaces/IWrappedToken.sol

pragma solidity ^0.6.12;

interface IWrappedToken {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address account) external returns (uint256);
    function transfer(address dst, uint wad) external returns (bool);
}


// File contracts/interfaces/IHordConfiguration.sol

pragma solidity 0.6.12;

/**
 * IHordConfiguration contract.
 * @author Nikola Madjarevic
 * Date created: 4.8.21.
 * Github: madjarevicn
 */
interface IHordConfiguration {
    function hordToken() external view returns(address);
    function minChampStake() external view returns(uint256);
    function minFollowerUSDStake() external view returns(uint256);
    function maxFollowerUSDStake() external view returns(uint256);
    function gasUtilizationRatio() external view returns(uint256);
    function percentPrecision() external view returns(uint256);
    function maxUSDAllocationPerTicket() external view returns (uint256);
    function totalSupplyHPoolTokens() external view returns (uint256);
    function ticketSaleDurationSecs() external view returns (uint256);
    function privateSubscriptionDurationSecs() external view returns (uint256);
    function publicSubscriptionDurationSecs() external view returns (uint256);
    function maxDurationValue() external view returns (uint256);
    function percentBurntFromPublicSubscription() external view returns (uint256);
    function championFeePercent() external view returns (uint256);
    function protocolFeePercent() external view returns (uint256);
    function tradingFeePercent() external view returns (uint256);
    function minTimeToStake() external view returns (uint256);
    function minAmountToStake() external view returns (uint256);
    function platformStakeRatio() external view returns (uint256);
    function calculateTradingFee(uint256 amount) external view returns (uint256);
    function exitFeeAmount(uint256 usdAmountWei) external view returns (uint256);
}


// File contracts/interfaces/IPool.sol

pragma solidity 0.6.12;


/**
 * IHPool contract.
 * @author Nikola Madjarevic
 * Date created: 29.7.21.
 * Github: madjarevicn
 */
interface IPool {

    function initialize(
        uint256 _hPoolId,
        uint256 _bePoolId,
        address _hordCongress,
        address _hordMaintainersRegistry,
        address _hordPoolManager,
        address _championAddress,
        address _signatureValidator,
        address _hPoolImplementation,
        address _hPoolHelper,
        address uniswapRouter
    ) external;
    function depositBudget(uint256 usdValueWei, uint256 totalDeposit) external payable;
    function mintHPoolToken(
        string memory name,
        string memory symbol,
        uint256 _totalSupply,
        address hordConfiguration,
        address matchingMarket
    ) external;
    function swapExactTokensForTokens(
        address[] memory path,
        address token,
        bool isWETHSource,
        uint256 amountSrc,
        uint256 minAmountOut,
        bool isLiquidation
    ) external returns (uint256);
    function isPoolEnded() external view returns (bool);
    function championAddress() external view returns (address);
    function bePoolId() external view returns (uint256);
    function totalBaseAssetAtLaunch() external view returns (uint256);
    function paused() external view returns (bool);
}


// File contracts/interfaces/IHPoolManager.sol

pragma solidity 0.6.12;

/**
 * IHPoolManager contract.
 * @author Nikola Madjarevic
 * Date created: 20.7.21.
 * Github: madjarevicn
 */
interface IHPoolManager {
    function setActivityForExactHPool(uint256 poolId, bool paused) external;
    function getPoolInfo(uint256 poolId)
    external
    view
    returns
    (
        uint256,
        uint256,
        address,
        uint256,
        uint256,
        bool,
        uint256,
        address,
        uint256,
        uint256,
        uint256,
        uint256
    );
    function addProtocolFeeETH() payable external;
    function getUserSubscriptionForPool(uint256 poolId, address user) external view returns (uint256, uint256);
    function getLatestETH2USDPrice() external view returns (int256);
    function getDecimalsReturnPrecision() external view returns (uint256);
    function convertUSDValueToETH(uint256 amount) external view returns (uint256);
    function isWhitelisted(address hPoolToken) external view returns (bool);
    function getTradingFee(uint256 amount) external view returns (uint256, uint256);
    function hordCongress() external view returns (address);
    function privateSubscribeForHPool(uint256 poolId) external payable;
    function publicSubscribeForHPool(uint256 poolId) external payable;
}


// File contracts/interfaces/ISignatureValidator.sol

pragma solidity 0.6.12;

/**
 * ISignatureValidator contract.
 * @author Nikola Madjarevic
 * Date created: 30.9.21.
 * Github: madjarevicn
 */
interface ISignatureValidator {

    function recoverSignatureBuyOrderRatio(
        address dstToken,
        uint256 ratio,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureTradeOrder(
        address srcToken,
        address dstToken,
        uint256 amountSrc,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureSellLimit(
        address srcToken,
        address dstToken,
        uint256 priceUSD,
        uint256 amountSrc,
        uint256 validUntil,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureBuyLimit(
        address srcToken,
        address dstToken,
        uint256 priceUSD,
        uint256 amountUSD,
        uint256 validUntil,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureStopLoss(
        address srcToken,
        address dstToken,
        uint256 priceUSD,
        uint256 amountSrc,
        uint256 validUntil,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureEndPool(
        uint256 poolId,
        uint256 poolNonce,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureOpenOrder(
        uint256 poolId,
        uint256 tokenId,
        uint256 amountUSDToWithdraw,
        uint256 amountOfTokensToReturn,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureCloseOrder(
        uint256 tokenId,
        uint256 totalTokensToBeReceived,
        uint256 finalTokenPrice,
        uint256 amountOfTokensToReceiveNow,
        address tokenAddress,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureClosePortion(
        uint256 tokenId,
        uint256 portionId,
        uint256 amountOfTokensToReceive,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

}


// File contracts/interfaces/IMaintainersRegistry.sol

pragma solidity 0.6.12;

/**
 * IMaintainersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/system/HordUpgradable.sol

pragma solidity 0.6.12;

/**
 * HordUpgradables contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
contract HordUpgradable {

    address public hordCongress;
    IMaintainersRegistry public maintainersRegistry;

    event MaintainersRegistrySet(address maintainersRegistry);
    event CongressAndMaintainersSet(address hordCongress, address maintainersRegistry);

    // Only maintainer modifier
    modifier onlyMaintainer {
        require(maintainersRegistry.isMaintainer(msg.sender), "Hord: Restricted only to Maintainer");
        _;
    }

    // Only chainport congress modifier
    modifier onlyHordCongress {
        require(msg.sender == hordCongress, "Hord: Restricted only to HordCongress");
        _;
    }

    modifier onlyHordCongressOrMaintainer {
        require(msg.sender == hordCongress || maintainersRegistry.isMaintainer(msg.sender),
            "Hord: Only Congress or Maintainer."
        );
        _;
    }

    function setCongressAndMaintainers(
        address _hordCongress,
        address _maintainersRegistry
    )
    internal
    {
        require(_hordCongress != address(0), "HordCongress can not be 0x0 address");
        require(_maintainersRegistry != address(0), "MaintainersRegistry can not be 0x0 address");

        hordCongress = _hordCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);

        emit CongressAndMaintainersSet(hordCongress, address(maintainersRegistry));
    }

}


// File contracts/libraries/SafeMath.sol

pragma solidity 0.6.12;


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


// File contracts/pools/HPoolHelper.sol

pragma solidity 0.6.12;









/**
 * HPoolHelper contract.
 * @author Srdjan Simonovic
 * Date created: 11.12.21.
 * Github: s2imonovic
 */
contract HPoolHelper is Initializable, HordUpgradable {

    using SafeMath for *;

    // Mapping is nonce used.
    mapping(uint256 => mapping(address => bool)) public isNonceUsedForExactPool;
    // Represent best buy route for exact token
    mapping(address => address[]) public bestBuyRoutes;
    // Constant, representing 1ETH in WEI units.
    uint256 constant one = 1e18;

    IUniswapV2Router02 private uniswapRouter;
    IWrappedToken private wrappedToken;
    IHPoolManager private hPoolManager;
    ISignatureValidator private signatureValidator;

    event NonceUsed(uint256 nonce, address pool);
    event HPoolManagerSet(address hPoolManager);
    event SignatureValidatorSet(address signatureValidator);
    event UniswapRouterSet(address uniswapRouter);

    function initialize(
        address _hordCongress,
        address _maintainersRegistry,
        address _uniswapRouter,
        address _signatureValidator
    )
    external
    initializer
    {
        require(_uniswapRouter != address(0), "Uniswap router can not be 0x0 address.");

        setCongressAndMaintainers(_hordCongress, _maintainersRegistry);

        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        wrappedToken = IWrappedToken(uniswapRouter.WETH());
        signatureValidator = ISignatureValidator(_signatureValidator);
    }

    modifier onlyIfPooIsNotEnded(address poolAddress) {
        require(!IPool(poolAddress).isPoolEnded(), "pool is ended.");
        _;
    }

    modifier onlyIfOrderValid(uint256 validUntil) {
        require(block.timestamp < validUntil, "Time elapsed.");
        _;
    }

    /**
        * @notice          Function to mark nonce as used and check is nonce already used.
         * @param           poolNonce is nonce for which we perform check.
     */
    function useNonce(
        uint256 poolNonce,
        address poolAddress
    )
    public
    {
        require(!isNonceUsedForExactPool[poolNonce][poolAddress], "used nonce.");
        isNonceUsedForExactPool[poolNonce][poolAddress] = true;
        emit NonceUsed(poolNonce, poolAddress);
    }

    function isChampionAddress(
        address signer,
        IPool pool
    )
    public
    view
    {
        require(signer == pool.championAddress(), "Invalid address.");
    }

    function setUniswapRouter(
        address _uniswapRouter
    )
    external
    onlyHordCongress
    {
        require(_uniswapRouter != address(0), "UniswapRouter can not be 0x0 address.");

        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        emit UniswapRouterSet(_uniswapRouter);
    }

    function setSignatureValidator(
        address _signatureValidator
    )
    external
    onlyHordCongress
    {
        require(_signatureValidator != address(0), "SignatureValidator can not be 0x0 address.");

        signatureValidator = ISignatureValidator(_signatureValidator);
        emit SignatureValidatorSet(_signatureValidator);
    }

    function setHPoolManager(
        address _hPoolManager
    )
    external
    onlyHordCongress
    {
        require(_hPoolManager != address(0), "HPoolManager can not be 0x0 address.");

        hPoolManager = IHPoolManager(_hPoolManager);
        emit HPoolManagerSet(_hPoolManager);
    }

    /**
          * @notice     Function to verify and execute BuyOrderRatio TradeType
           * @param      sigR is first 32 bytes of signature
           * @param      sigS is second 32 bytes of signature
           * @param      sigV is the last byte of signature
    */
    function verifyAndExecuteBuyOrderRatio(
        address[] memory path,
        address[] memory addresses,
        uint256[] memory values,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    onlyMaintainer
    onlyIfPooIsNotEnded(addresses[0])
    {
        require(IPool(addresses[0]).paused(), "Pausable: not paused");
        useNonce(values[3], addresses[0]);

        IPool pool = IPool(addresses[0]);

        address signer = signatureValidator.recoverSignatureBuyOrderRatio(
            addresses[1],
            values[0],
            values[3],
            pool.bePoolId(),
            sigR,
            sigS,
            sigV
        );
        isChampionAddress(signer, pool);

        uint256 actualAmountPerRatio = values[0].mul(pool.totalBaseAssetAtLaunch()).div(100 * one);
        require(values[1] == actualAmountPerRatio, "amount is not correct.");

        pool.swapExactTokensForTokens(path, addresses[1], true, values[1], values[2], false);
        bestBuyRoutes[addresses[1]] = path;
    }

    /**
           * @notice     Function to verify and execute TradeOrder TradeType
           * @param      sigR is first 32 bytes of signature
           * @param      sigS is second 32 bytes of signature
           * @param      sigV is the last byte of signature
    */
    function verifyAndExecuteTradeOrderExactAmount(
        address[] memory path,
        address[] memory addresses,
        uint256[] memory values,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    onlyMaintainer
    onlyIfPooIsNotEnded(addresses[0])
    {
        require(IPool(addresses[0]).paused(), "Pausable: not paused");

        useNonce(values[3], addresses[0]);

        IPool pool = IPool(addresses[0]);

        address signer = signatureValidator.recoverSignatureTradeOrder(
            addresses[1],
            addresses[2],
            values[0],
            values[3],
            pool.bePoolId(),
            sigR,
            sigS,
            sigV
        );
        isChampionAddress(signer, pool);

        if(addresses[1] == address(wrappedToken)) {
            pool.swapExactTokensForTokens(path, addresses[2], true, values[1], values[2], false);
        } else {
            pool.swapExactTokensForTokens(path, addresses[1], false, values[1], values[2], false);
            bestBuyRoutes[addresses[1]] = path;
        }
    }

    /**
           * @notice     Function to verify and execute TradeOrder TradeType
           * @param      sigR is first 32 bytes of signature
           * @param      sigS is second 32 bytes of signature
           * @param      sigV is the last byte of signature
    */
    function verifyAndExecuteBuyLimit(
        address[] memory path,
        address[] memory addresses,
        uint256[] memory values,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    onlyMaintainer
    onlyIfPooIsNotEnded(addresses[0])
    onlyIfOrderValid(values[2])
    {
        require(IPool(addresses[0]).paused(), "Pausable: not paused");
        useNonce(values[3], addresses[0]);

        IPool pool = IPool(addresses[0]);

        address signer = signatureValidator.recoverSignatureBuyLimit(
            addresses[1],
            addresses[2],
            values[0],
            values[1],
            values[2],
            values[3],
            pool.bePoolId(),
            sigR,
            sigS,
            sigV
        );

        uint256 amountSrc = hPoolManager.convertUSDValueToETH(values[1]);

        isChampionAddress(signer, pool);
        pool.swapExactTokensForTokens(path, addresses[2], true, amountSrc, values[4], false);
        bestBuyRoutes[addresses[2]] = path;
    }

    /**
           * @notice     Function to verify and execute TradeOrder TradeType
           * @param      sigR is first 32 bytes of signature
           * @param      sigS is second 32 bytes of signature
           * @param      sigV is the last byte of signature
    */
    function verifyAndExecuteSellLimit(
        address[] memory path,
        address[] memory addresses,
        uint256[] memory values,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    onlyMaintainer
    onlyIfPooIsNotEnded(addresses[0])
    onlyIfOrderValid(values[2])
    {
        require(IPool(addresses[0]).paused(), "Pausable: not paused");
        useNonce(values[3], addresses[0]);

        IPool pool = IPool(addresses[0]);

        address signer = signatureValidator.recoverSignatureSellLimit(
            addresses[1],
            addresses[2],
            values[0],
            values[1],
            values[2],
            values[3],
            pool.bePoolId(),
            sigR,
            sigS,
            sigV
        );
        isChampionAddress(signer, pool);

        IPool(addresses[0]).swapExactTokensForTokens(path, addresses[1], false, values[1], values[4], false);
    }

    /**
           * @notice     Function to verify and execute TradeOrder TradeType
           * @param      sigR is first 32 bytes of signature
           * @param      sigS is second 32 bytes of signature
           * @param      sigV is the last byte of signature
    */
    function verifyAndExecuteStopLoss(
        address[] memory path,
        address[] memory addresses,
        uint256[] memory values,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    onlyMaintainer
    onlyIfPooIsNotEnded(addresses[0])
    onlyIfOrderValid(values[2])
    {
        require(IPool(addresses[0]).paused(), "Pausable: not paused");
        useNonce(values[3], addresses[0]);

        IPool pool = IPool(addresses[0]);

        address signer = signatureValidator.recoverSignatureStopLoss(
            addresses[1],
            addresses[2],
            values[0],
            values[1],
            values[2],
            values[3],
            pool.bePoolId(),
            sigR,
            sigS,
            sigV
        );
        isChampionAddress(signer, pool);

        pool.swapExactTokensForTokens(path, addresses[1], false, values[1], values[4], false);
    }

    function setBestBuyRoute(address token, address[] memory path) external onlyMaintainer {
        require(path.length > 1, "Invalid path.");
        bestBuyRoutes[token] = path;
    }

    function getBestSellRoute(address token) view external returns(address[] memory){
        uint256 routeLength = bestBuyRoutes[token].length;

        if(routeLength == 0) {
            return bestBuyRoutes[token];
        }

        address[] memory sellRoute = new address[](routeLength);

        uint256 counter = routeLength - 1;

        for(uint256 i = 0; i < routeLength; i++) {
            sellRoute[i] = bestBuyRoutes[token][counter];
            counter--;
        }

        return sellRoute;
    }

    function getBestBuyRoute(address token) view external returns(address[] memory){
        return bestBuyRoutes[token];
    }

}