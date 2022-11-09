// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICERC20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICEther {
    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint[] memory);

    function checkMembership(address account, address cToken)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITradingAccount {
    event Deposit(bool isETH, uint256 amount);
    event Withdraw(bool isETH, uint256 cTokenAmount, uint256 underlyingAmount);
    event OpenLong(uint256 ethSize);
    event OpenShort(uint256 usdcSize);
    event CloseLong(uint256 repayAmount, bool closeAll);
    event CloseShort(uint256 repayAmount, bool closeAll);
    event LimitOpenLong(
        uint256 orderId,
        uint256 ethSize,
        uint256 limitPrice,
        uint256 expireAt,
        address indexed keeper
    );
    event LimitOpenShort(
        uint256 orderId,
        uint256 usdcSize,
        uint256 limitPrice,
        uint256 expireAt,
        address indexed keeper
    );
    event CancelLimitOrder(uint256 orderId);
    event ExecuteLimitOrder(uint256 orderId);

    struct LimitOrder {
        bool isLong;
        bool isCanceled;
        uint256 openSize;
        uint256 limitPrice;
        uint256 dealPrice;
        uint256 expireAt;
        address keeper;
    }

    function getLimitOrder(uint256 orderId)
        external
        view
        returns (
            bool isLong,
            bool isCanceled,
            uint256 openSize,
            uint256 limitPrice,
            uint256 dealPrice,
            uint256 expireAt,
            address keeper
        );

    function lastOrderId() external view returns (uint256);

    function weth() external view returns (address);

    function usdc() external view returns (address);

    function uniswapV2Pair() external view returns (address);

    function cETH() external view returns (address);

    function cUSDC() external view returns (address);

    function comptroller() external view returns (address);

    function priceFeed() external view returns (address);

    function getLatestPrice() external view returns (uint256 price);

    function initialize(
        address owner_,
        address weth_,
        address usdc_,
        address uniswapV2Pair_,
        address cETH,
        address cUSDC,
        address comptroller,
        address priceFeed
    ) external;

    function depositETH() external payable;

    function depositUSDC(uint256 amount) external;

    function withdrawETH(uint256 cEthAmount, uint256 ethAmount) external;

    function withdrawUSDC(uint256 cUsdcAmount, uint256 usdcAmount) external;

    function openLong(uint256 ethSize) external;

    function openShort(uint256 usdcSize) external;

    function closeLong(uint256 usdcAmount, bool closeAll)
        external
        returns (uint256 repayAmount);

    function closeShort(uint256 ethAmount, bool closeAll)
        external
        returns (uint256 repayAmount);

    function limitOpenLong(
        uint256 ethSize,
        uint256 limitPrice,
        uint256 expireAt,
        address keeper
    ) external returns (uint256 orderId);

    function limitOpenShort(
        uint256 usdcSize,
        uint256 limitPrice,
        uint256 expireAt,
        address keeper
    ) external returns (uint256 orderId);

    function cancelLimitOrder(uint256 orderId) external;

    function executeLimitOrder(uint256 orderId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
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

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Callee.sol";
import "./interfaces/ICEther.sol";
import "./interfaces/ICERC20.sol";
import "./interfaces/IComptroller.sol";
import "./interfaces/ITradingAccount.sol";
import "./base/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TradingAccount is
    ITradingAccount,
    IUniswapV2Callee,
    Initializable,
    Ownable
{
    address public override weth;
    address public override usdc;
    address public override uniswapV2Pair;
    address public override cETH;
    address public override cUSDC;
    address public override comptroller;
    address public override priceFeed;
    uint256 public override lastOrderId;
    mapping(uint256 => LimitOrder) public override getLimitOrder;

    receive() external payable {
        assert(msg.sender == weth); // only accept ETH via fallback from the WETH contract
    }

    function initialize(
        address owner_,
        address weth_,
        address usdc_,
        address uniswapV2Pair_,
        address cETH_,
        address cUSDC_,
        address comptroller_,
        address priceFeed_
    ) external override initializer {
        owner = owner_;
        weth = weth_;
        usdc = usdc_;
        uniswapV2Pair = uniswapV2Pair_;
        cETH = cETH_;
        cUSDC = cUSDC_;
        comptroller = comptroller_;
        priceFeed = priceFeed_;
        address[] memory cTokens = new address[](2);
        cTokens[0] = cETH;
        cTokens[1] = cUSDC;
        IComptroller(comptroller).enterMarkets(cTokens);
    }

    function depositETH() external payable override onlyOwner {
        uint256 depositAmount = msg.value;
        ICEther(cETH).mint{value: depositAmount}();
        emit Deposit(true, depositAmount);
    }

    function depositUSDC(uint256 amount) external override onlyOwner {
        TransferHelper.safeTransferFrom(
            usdc,
            msg.sender,
            address(this),
            amount
        );
        IERC20(usdc).approve(cUSDC, amount);
        require(ICERC20(cUSDC).mint(amount) == 0, "mint error");
        emit Deposit(false, amount);
    }

    function withdrawETH(uint256 cEthAmount, uint256 ethAmount)
        external
        override
        onlyOwner
    {
        require(
            (cEthAmount > 0 && ethAmount == 0) ||
                (cEthAmount == 0 && ethAmount > 0),
            "one must be zero, one must be gt 0"
        );
        if (cEthAmount > 0) {
            require(ICEther(cETH).redeem(cEthAmount) == 0, "redeem error");
        } else {
            require(
                ICEther(cETH).redeemUnderlying(ethAmount) == 0,
                "redeem error"
            );
        }
        TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        emit Withdraw(true, cEthAmount, ethAmount);
    }

    function withdrawUSDC(uint256 cUsdcAmount, uint256 usdcAmount)
        external
        override
        onlyOwner
    {
        require(
            (cUsdcAmount > 0 && usdcAmount == 0) ||
                (cUsdcAmount == 0 && usdcAmount > 0),
            "one must be zero, one must be gt 0"
        );
        if (cUsdcAmount > 0) {
            require(ICERC20(cUSDC).redeem(cUsdcAmount) == 0, "redeem error");
        } else {
            require(
                ICERC20(cUSDC).redeemUnderlying(usdcAmount) == 0,
                "redeem error"
            );
        }
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));
        TransferHelper.safeTransfer(usdc, msg.sender, usdcBalance);
        emit Withdraw(false, cUsdcAmount, usdcAmount);
    }

    function openLong(uint256 ethSize) external override onlyOwner {
        _openLong(ethSize);
        emit OpenLong(ethSize);
    }

    function openShort(uint256 usdcSize) external override onlyOwner {
        _openShort(usdcSize);
        emit OpenShort(usdcSize);
    }

    function closeLong(uint256 usdcAmount, bool closeAll)
        external
        override
        onlyOwner
        returns (uint256 repayAmount)
    {
        uint256 borrowBalance = ICERC20(cUSDC).borrowBalanceStored(
            address(this)
        );
        repayAmount = closeAll ? borrowBalance : usdcAmount;

        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(uniswapV2Pair)
            .getReserves();
        uint256 reserveIn;
        uint256 reserveOut;
        if (IUniswapV2Pair(uniswapV2Pair).token0() == usdc) {
            reserveIn = reserve1;
            reserveOut = reserve0;
        } else {
            reserveIn = reserve0;
            reserveOut = reserve1;
        }
        uint256 amountIn = _getAmountIn(repayAmount, reserveIn, reserveOut);

        address token0 = IUniswapV2Pair(uniswapV2Pair).token0();
        uint256 amount0Out;
        uint256 amount1Out;
        if (token0 == usdc) {
            amount0Out = repayAmount;
        } else {
            amount1Out = repayAmount;
        }

        require(ICEther(cETH).redeemUnderlying(amountIn) == 0, "redeem error");
        IWETH(weth).deposit{value: amountIn}();
        TransferHelper.safeTransfer(weth, uniswapV2Pair, amountIn);
        IUniswapV2Pair(uniswapV2Pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            ""
        );

        require(ICERC20(cUSDC).repayBorrow(repayAmount) == 0, "repay error");
        emit CloseLong(repayAmount, closeAll);
    }

    function closeShort(uint256 ethAmount, bool closeAll)
        external
        override
        onlyOwner
        returns (uint256 repayAmount)
    {
        uint256 borrowBalance = ICEther(cETH).borrowBalanceStored(
            address(this)
        );
        repayAmount = closeAll ? borrowBalance : ethAmount;

        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(uniswapV2Pair)
            .getReserves();
        uint256 reserveIn;
        uint256 reserveOut;
        if (IUniswapV2Pair(uniswapV2Pair).token0() == weth) {
            reserveIn = reserve1;
            reserveOut = reserve0;
        } else {
            reserveIn = reserve0;
            reserveOut = reserve1;
        }
        uint256 amountIn = _getAmountIn(repayAmount, reserveIn, reserveOut);

        address token0 = IUniswapV2Pair(uniswapV2Pair).token0();
        uint256 amount0Out;
        uint256 amount1Out;
        if (token0 == weth) {
            amount0Out = repayAmount;
        } else {
            amount1Out = repayAmount;
        }

        require(ICERC20(cUSDC).redeemUnderlying(amountIn) == 0, "redeem error");
        TransferHelper.safeTransfer(usdc, uniswapV2Pair, amountIn);
        IUniswapV2Pair(uniswapV2Pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            ""
        );

        IWETH(weth).withdraw(repayAmount);
        ICEther(cETH).repayBorrow{value: repayAmount}();
        emit CloseShort(repayAmount, closeAll);
    }

    function limitOpenLong(
        uint256 ethSize,
        uint256 limitPrice,
        uint256 expireAt,
        address keeper
    ) external override onlyOwner returns (uint256 orderId) {
        orderId = _newLimitOrder(true, ethSize, limitPrice, expireAt, keeper);
        emit LimitOpenLong(orderId, ethSize, limitPrice, expireAt, keeper);
    }

    function limitOpenShort(
        uint256 usdcSize,
        uint256 limitPrice,
        uint256 expireAt,
        address keeper
    ) external override onlyOwner returns (uint256 orderId) {
        orderId = _newLimitOrder(false, usdcSize, limitPrice, expireAt, keeper);
        emit LimitOpenShort(orderId, usdcSize, limitPrice, expireAt, keeper);
    }

    function cancelLimitOrder(uint256 orderId) external override onlyOwner {
        require(orderId > 0 && orderId <= lastOrderId, "order not found");
        LimitOrder memory order = getLimitOrder[orderId];
        require(!order.isCanceled, "already canceled");
        require(order.dealPrice == 0, "already dealt");
        require(order.expireAt > block.timestamp, "already expired");
        order.isCanceled = true;
        getLimitOrder[orderId] = order;
        emit CancelLimitOrder(orderId);
    }

    function executeLimitOrder(uint256 orderId) external override {
        require(orderId > 0 && orderId <= lastOrderId, "order not found");
        LimitOrder memory order = getLimitOrder[orderId];
        require(order.keeper == msg.sender, "require keeper");
        require(!order.isCanceled, "already canceled");
        require(order.dealPrice == 0, "already dealt");
        require(order.expireAt > block.timestamp, "already expired");

        uint256 latestPrice = getLatestPrice();
        if (order.isLong) {
            require(order.limitPrice >= latestPrice, "not reach limitPrice");
            _openLong(order.openSize);
        } else {
            require(order.limitPrice <= latestPrice, "not reach limitPrice");
            _openShort(order.openSize);
        }
        emit ExecuteLimitOrder(orderId);
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == uniswapV2Pair, "only uniswapV2Pair");
        address token0 = IUniswapV2Pair(uniswapV2Pair).token0();
        address token1 = IUniswapV2Pair(uniswapV2Pair).token1();
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(uniswapV2Pair)
            .getReserves();

        address tokenOutput;
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 amountOut;

        if (amount0 > 0) {
            tokenOutput = token0;
            reserveIn = reserve1;
            reserveOut = reserve0;
            amountOut = amount0;
        } else {
            tokenOutput = token1;
            reserveIn = reserve0;
            reserveOut = reserve1;
            amountOut = amount1;
        }
        uint256 amountIn = _getAmountIn(amountOut, reserveIn, reserveOut);

        if (tokenOutput == usdc) {
            IERC20(usdc).approve(cUSDC, amountOut);
            require(ICERC20(cUSDC).mint(amountOut) == 0, "mint error");
            require(ICEther(cETH).borrow(amountIn) == 0, "borrow error");
            IWETH(weth).deposit{value: amountIn}();
            TransferHelper.safeTransfer(weth, uniswapV2Pair, amountIn);
        } else {
            IWETH(weth).withdraw(amountOut);
            ICEther(cETH).mint{value: amountOut}();
            require(ICERC20(cUSDC).borrow(amountIn) == 0, "borrow error");
            TransferHelper.safeTransfer(usdc, uniswapV2Pair, amountIn);
        }
    }

    function getLatestPrice() public view override returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(priceFeed)
            .latestRoundData();
        return uint256(price);
    }

    function _openLong(uint256 ethSize) internal {
        address token0 = IUniswapV2Pair(uniswapV2Pair).token0();
        uint256 amount0Out;
        uint256 amount1Out;
        if (token0 == weth) {
            amount0Out = ethSize;
        } else {
            amount1Out = ethSize;
        }
        IUniswapV2Pair(uniswapV2Pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            "0x1234"
        );
    }

    function _openShort(uint256 usdcSize) internal {
        address token0 = IUniswapV2Pair(uniswapV2Pair).token0();
        uint256 amount0Out;
        uint256 amount1Out;
        if (token0 == usdc) {
            amount0Out = usdcSize;
        } else {
            amount1Out = usdcSize;
        }
        IUniswapV2Pair(uniswapV2Pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            "0x1234"
        );
    }

    function _newLimitOrder(
        bool isLong,
        uint256 openSize,
        uint256 limitPrice,
        uint256 expireAt,
        address keeper
    ) internal returns (uint256 orderId) {
        require(expireAt > block.timestamp, "expireAt <= block.timestamp");
        if (isLong) {
            require(limitPrice < getLatestPrice(), "limitPrice >= latestPrice");
        } else {
            require(limitPrice > getLatestPrice(), "limitPrice <= latestPrice");
        }

        LimitOrder memory order = LimitOrder({
            isLong: isLong,
            isCanceled: false,
            openSize: openSize,
            limitPrice: limitPrice,
            dealPrice: 0,
            expireAt: expireAt,
            keeper: keeper
        });
        lastOrderId += 1;
        getLimitOrder[lastOrderId] = order;
        orderId = lastOrderId;
        return orderId;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function _getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        require(amountOut > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }
}