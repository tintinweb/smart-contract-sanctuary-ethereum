// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {PriceOracle} from "./PriceOracle.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Extended} from "./interfaces/IERC20Extended.sol";

import {IPriceOracle} from "./interfaces/IPriceOracle.sol";

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

contract ConnextPriceOracle is PriceOracle {
  using SafeMath for uint256;
  using SafeERC20 for IERC20Extended;

  address public admin;
  address public wrapped;
  address public v1PriceOracle;

  /// @notice Chainlink Aggregators
  mapping(address => AggregatorV3Interface) public aggregators;

  struct PriceInfo {
    address token; // Address of token contract, TOKEN
    address baseToken; // Address of base token contract, BASETOKEN
    address lpToken; // Address of TOKEN-BASETOKEN pair contract
    bool active; // Active status of price record 0
  }

  mapping(address => PriceInfo) public priceRecords;
  mapping(address => uint256) public assetPrices;

  event NewAdmin(address oldAdmin, address newAdmin);
  event PriceRecordUpdated(address token, address baseToken, address lpToken, bool _active);
  event DirectPriceUpdated(address token, uint256 oldPrice, uint256 newPrice);
  event AggregatorUpdated(address tokenAddress, address source);
  event V1PriceOracleUpdated(address oldAddress, address newAddress);

  modifier onlyAdmin() {
    require(msg.sender == admin, "caller is not the admin");
    _;
  }

  constructor(address _wrapped) {
    wrapped = _wrapped;
    admin = msg.sender;
  }

  function getTokenPrice(address _tokenAddress) public view override returns (uint256) {
    address tokenAddress = _tokenAddress;
    if (_tokenAddress == address(0)) {
      tokenAddress = wrapped;
    }
    uint256 tokenPrice = assetPrices[tokenAddress];
    if (tokenPrice == 0) {
      tokenPrice = getPriceFromOracle(tokenAddress);
    }
    if (tokenPrice == 0) {
      tokenPrice = getPriceFromDex(tokenAddress);
    }
    if (tokenPrice == 0 && v1PriceOracle != address(0)) {
      tokenPrice = IPriceOracle(v1PriceOracle).getTokenPrice(tokenAddress);
    }
    return tokenPrice;
  }

  function getPriceFromDex(address _tokenAddress) public view returns (uint256) {
    PriceInfo storage priceInfo = priceRecords[_tokenAddress];
    if (priceInfo.active) {
      uint256 rawTokenAmount = IERC20Extended(priceInfo.token).balanceOf(priceInfo.lpToken);
      uint256 tokenDecimalDelta = 18 - uint256(IERC20Extended(priceInfo.token).decimals());
      uint256 tokenAmount = rawTokenAmount.mul(10**tokenDecimalDelta);
      uint256 rawBaseTokenAmount = IERC20Extended(priceInfo.baseToken).balanceOf(priceInfo.lpToken);
      uint256 baseTokenDecimalDelta = 18 - uint256(IERC20Extended(priceInfo.baseToken).decimals());
      uint256 baseTokenAmount = rawBaseTokenAmount.mul(10**baseTokenDecimalDelta);
      uint256 baseTokenPrice = getTokenPrice(priceInfo.baseToken);
      uint256 tokenPrice = baseTokenPrice.mul(baseTokenAmount).div(tokenAmount);

      return tokenPrice;
    } else {
      return 0;
    }
  }

  function getPriceFromOracle(address _tokenAddress) public view returns (uint256) {
    uint256 chainLinkPrice = getPriceFromChainlink(_tokenAddress);
    return chainLinkPrice;
  }

  function getPriceFromChainlink(address _tokenAddress) public view returns (uint256) {
    AggregatorV3Interface aggregator = aggregators[_tokenAddress];
    if (address(aggregator) != address(0)) {
      (, int256 answer, , , ) = aggregator.latestRoundData();

      // It's fine for price to be 0. We have two price feeds.
      if (answer == 0) {
        return 0;
      }

      // Extend the decimals to 1e18.
      uint256 retVal = uint256(answer);
      uint256 price = retVal.mul(10**(18 - uint256(aggregator.decimals())));

      return price;
    }
  }

  function setDexPriceInfo(
    address _token,
    address _baseToken,
    address _lpToken,
    bool _active
  ) external onlyAdmin {
    PriceInfo storage priceInfo = priceRecords[_token];
    uint256 baseTokenPrice = getTokenPrice(_baseToken);
    require(baseTokenPrice > 0, "invalid base token");
    priceInfo.token = _token;
    priceInfo.baseToken = _baseToken;
    priceInfo.lpToken = _lpToken;
    priceInfo.active = _active;
    emit PriceRecordUpdated(_token, _baseToken, _lpToken, _active);
  }

  function setDirectPrice(address _token, uint256 _price) external onlyAdmin {
    emit DirectPriceUpdated(_token, assetPrices[_token], _price);
    assetPrices[_token] = _price;
  }

  function setV1PriceOracle(address _v1PriceOracle) external onlyAdmin {
    emit V1PriceOracleUpdated(v1PriceOracle, _v1PriceOracle);
    v1PriceOracle = _v1PriceOracle;
  }

  function setAdmin(address newAdmin) external onlyAdmin {
    address oldAdmin = admin;
    admin = newAdmin;

    emit NewAdmin(oldAdmin, newAdmin);
  }

  function setAggregators(address[] calldata tokenAddresses, address[] calldata sources) external onlyAdmin {
    for (uint256 i = 0; i < tokenAddresses.length; i++) {
      aggregators[tokenAddresses[i]] = AggregatorV3Interface(sources[i]);
      emit AggregatorUpdated(tokenAddresses[i], sources[i]);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

abstract contract PriceOracle {
  /// @notice Indicator that this is a PriceOracle contract (for inspection)
  bool public constant isPriceOracle = true;

  /**
   * @notice Get the price of a token
   * @param token The token to get the price of
   * @return The asset price mantissa (scaled by 1e18).
   *  Zero means the price is unavailable.
   */
  function getTokenPrice(address token) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Extended {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IPriceOracle {
  /**
   * @notice Get the price of a token
   * @param token The token to get the price of
   * @return The asset price mantissa (scaled by 1e18).
   *  Zero means the price is unavailable.
   */
  function getTokenPrice(address token) external view returns (uint256);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../interfaces/IStableSwap.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TestStableSwap {
  using SafeMath for uint256;

  IStableSwap public swap;
  IERC20 public lpToken;
  uint8 public n;

  uint256 public constant MAX_INT = 2**256 - 1;

  constructor(
    IStableSwap swapContract,
    IERC20 lpTokenContract,
    uint8 numOfTokens
  ) {
    swap = swapContract;
    lpToken = lpTokenContract;
    n = numOfTokens;

    // Pre-approve tokens
    for (uint8 i; i < n; i++) {
      swap.getToken(i).approve(address(swap), MAX_INT);
    }
    lpToken.approve(address(swap), MAX_INT);
  }

  event PoolCreated(address assetA, address assetB, uint256 seedA, uint256 seedB);

  event Swapped(address assetIn, address assetOut, uint256 amountIn, uint256 amountOut);

  // Hold mapping of swaps
  mapping(address => address) poolAssets;

  function swapExact(
    uint256 amountIn,
    address assetIn,
    address assetOut
  ) external payable returns (uint256) {
    // make sure pool is setup
    require(poolAssets[assetIn] == assetOut, "!setup");

    // make sure theres enough balance
    bool assetOutIsNative = assetOut == address(0);
    if (assetOutIsNative) {
      require(address(this).balance >= amountIn, "!bal");
    } else {
      require(IERC20(assetOut).balanceOf(address(this)) >= amountIn, "!bal");
    }

    // transfer in (simple 1:1)
    if (assetIn == address(0)) {
      require(msg.value == amountIn, "!val");
    } else {
      SafeERC20.safeTransferFrom(IERC20(assetIn), msg.sender, address(this), amountIn);
    }

    // transfer out (simple 1:1)
    if (assetOutIsNative) {
      Address.sendValue(payable(msg.sender), amountIn);
    } else {
      SafeERC20.safeTransfer(IERC20(assetOut), msg.sender, amountIn);
    }

    // emit
    emit Swapped(assetIn, assetOut, amountIn, amountIn);

    return amountIn;
  }

  function setupPool(
    address assetA,
    address assetB,
    uint256 seedA,
    uint256 seedB
  ) external payable {
    // Save pools
    poolAssets[assetA] = assetB;

    poolAssets[assetB] = assetA;

    // Transfer funds to contract
    if (assetA == address(0)) {
      require(msg.value == seedA, "!seedA");
    } else {
      SafeERC20.safeTransferFrom(IERC20(assetA), msg.sender, address(this), seedA);
    }

    if (assetB == address(0)) {
      require(msg.value == seedB, "!seedB");
    } else {
      SafeERC20.safeTransferFrom(IERC20(assetB), msg.sender, address(this), seedB);
    }

    emit PoolCreated(assetA, assetB, seedA, seedB);
  }

  function test_swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy
  ) public {
    uint256 balanceBefore = swap.getToken(tokenIndexTo).balanceOf(address(this));
    uint256 returnValue = swap.swap(tokenIndexFrom, tokenIndexTo, dx, minDy, block.timestamp);
    uint256 balanceAfter = swap.getToken(tokenIndexTo).balanceOf(address(this));

    require(returnValue == balanceAfter.sub(balanceBefore), "swap()'s return value does not match received amount");
  }

  function test_addLiquidity(uint256[] calldata amounts, uint256 minToMint) public {
    uint256 balanceBefore = lpToken.balanceOf(address(this));
    uint256 returnValue = swap.addLiquidity(amounts, minToMint, MAX_INT);
    uint256 balanceAfter = lpToken.balanceOf(address(this));

    require(
      returnValue == balanceAfter.sub(balanceBefore),
      "addLiquidity()'s return value does not match minted amount"
    );
  }

  function test_removeLiquidity(uint256 amount, uint256[] memory minAmounts) public {
    uint256[] memory balanceBefore = new uint256[](n);
    uint256[] memory balanceAfter = new uint256[](n);

    for (uint8 i = 0; i < n; i++) {
      balanceBefore[i] = swap.getToken(i).balanceOf(address(this));
    }

    uint256[] memory returnValue = swap.removeLiquidity(amount, minAmounts, MAX_INT);

    for (uint8 i = 0; i < n; i++) {
      balanceAfter[i] = swap.getToken(i).balanceOf(address(this));
      require(
        balanceAfter[i].sub(balanceBefore[i]) == returnValue[i],
        "removeLiquidity()'s return value does not match received amounts of tokens"
      );
    }
  }

  function test_removeLiquidityImbalance(uint256[] calldata amounts, uint256 maxBurnAmount) public {
    uint256 balanceBefore = lpToken.balanceOf(address(this));
    uint256 returnValue = swap.removeLiquidityImbalance(amounts, maxBurnAmount, MAX_INT);
    uint256 balanceAfter = lpToken.balanceOf(address(this));

    require(
      returnValue == balanceBefore.sub(balanceAfter),
      "removeLiquidityImbalance()'s return value does not match burned lpToken amount"
    );
  }

  function test_removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount
  ) public {
    uint256 balanceBefore = swap.getToken(tokenIndex).balanceOf(address(this));
    uint256 returnValue = swap.removeLiquidityOneToken(tokenAmount, tokenIndex, minAmount, MAX_INT);
    uint256 balanceAfter = swap.getToken(tokenIndex).balanceOf(address(this));

    require(
      returnValue == balanceAfter.sub(balanceBefore),
      "removeLiquidityOneToken()'s return value does not match received token amount"
    );
  }

  receive() external payable {}

  fallback() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStableSwap {
  /*** EVENTS ***/

  // events replicated from SwapUtils to make the ABI easier for dumb
  // clients
  event TokenSwap(address indexed buyer, uint256 tokensSold, uint256 tokensBought, uint128 soldId, uint128 boughtId);
  event AddLiquidity(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256 lpTokenSupply);
  event RemoveLiquidityOne(
    address indexed provider,
    uint256 lpTokenAmount,
    uint256 lpTokenSupply,
    uint256 boughtId,
    uint256 tokensBought
  );
  event RemoveLiquidityImbalance(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event NewAdminFee(uint256 newAdminFee);
  event NewSwapFee(uint256 newSwapFee);
  event NewWithdrawFee(uint256 newWithdrawFee);
  event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
  event StopRampA(uint256 currentA, uint256 time);

  function swapExact(
    uint256 amountIn,
    address assetIn,
    address assetOut
  ) external payable returns (uint256);

  function getA() external view returns (uint256);

  function getToken(uint8 index) external view returns (IERC20);

  function getTokenIndex(address tokenAddress) external view returns (uint8);

  function getTokenBalance(uint8 index) external view returns (uint256);

  function getVirtualPrice() external view returns (uint256);

  // min return calculation functions
  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256);

  function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);

  function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);

  function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
    external
    view
    returns (uint256 availableTokenAmount);

  // state modifying functions
  function initialize(
    IERC20[] memory pooledTokens,
    uint8[] memory decimals,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    uint256 a,
    uint256 fee,
    uint256 adminFee,
    address lpTokenTargetAddress
  ) external;

  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external returns (uint256);

  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidity(
    uint256 amount,
    uint256[] calldata minAmounts,
    uint256 deadline
  ) external returns (uint256[] memory);

  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidityImbalance(
    uint256[] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This is modified from "@openzeppelin/contracts/token/ERC20/IERC20.sol"
// Modifications were made to make the tokenName, tokenSymbol, and
// tokenDecimals fields internal instead of private. Getters for them were
// removed to silence solidity inheritance issues

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) private balances;

  mapping(address => mapping(address => uint256)) private allowances;

  uint256 private supply;

  struct Token {
    string name;
    string symbol;
    uint8 decimals;
  }

  Token internal token;

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `_recipient` cannot be the zero address.
   * - the caller must have a balance of at least `_amount`.
   */
  function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `_spender` cannot be the zero address.
   */
  function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `_sender` and `recipient` cannot be the zero address.
   * - `_sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``_sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) public virtual override returns (bool) {
    _transfer(_sender, _recipient, _amount);
    _approve(
      _sender,
      msg.sender,
      allowances[_sender][msg.sender].sub(_amount, "ERC20: transfer amount exceeds allowance")
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `_spender` cannot be the zero address.
   */
  function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
    _approve(msg.sender, _spender, allowances[msg.sender][_spender].add(_addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `_spender` cannot be the zero address.
   * - `_spender` must have allowance for the caller of at least
   * `_subtractedValue`.
   */
  function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
    _approve(
      msg.sender,
      _spender,
      allowances[msg.sender][_spender].sub(_subtractedValue, "ERC20: decreased allowance below zero")
    );
    return true;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return supply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address _account) public view virtual override returns (uint256) {
    return balances[_account];
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
    return allowances[_owner][_spender];
  }

  /**
   * @dev Moves tokens `amount` from `_sender` to `_recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `_sender` cannot be the zero address.
   * - `_recipient` cannot be the zero address.
   * - `_sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address _sender,
    address _recipient,
    uint256 amount
  ) internal virtual {
    require(_sender != address(0), "ERC20: transfer from the zero address");
    require(_recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(_sender, _recipient, amount);

    balances[_sender] = balances[_sender].sub(amount, "ERC20: transfer amount exceeds balance");
    balances[_recipient] = balances[_recipient].add(amount);
    emit Transfer(_sender, _recipient, amount);
  }

  /** @dev Creates `_amount` tokens and assigns them to `_account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address _account, uint256 _amount) internal virtual {
    require(_account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), _account, _amount);

    supply = supply.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

  /**
   * @dev Destroys `_amount` tokens from `_account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `_account` cannot be the zero address.
   * - `_account` must have at least `_amount` tokens.
   */
  function _burn(address _account, uint256 _amount) internal virtual {
    require(_account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(_account, address(0), _amount);

    balances[_account] = balances[_account].sub(_amount, "ERC20: burn amount exceeds balance");
    supply = supply.sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  /**
   * @dev Sets `_amount` as the allowance of `_spender` over the `_owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `_owner` cannot be the zero address.
   * - `_spender` cannot be the zero address.
   */
  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) internal virtual {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");

    allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }

  /**
   * @dev Sets {decimals_} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals_} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    token.decimals = decimals_;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `_from` and `_to` are both non-zero, `_amount` of ``_from``'s tokens
   * will be to transferred to `_to`.
   * - when `_from` is zero, `_amount` tokens will be minted for `_to`.
   * - when `_to` is zero, `_amount` of ``_from``'s tokens will be burned.
   * - `_from` and `_to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./TestERC20.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/* This token is ONLY useful for testing
 * Anybody can mint as many tokens as they like
 * Anybody can burn anyone else's tokens
 */
contract WETH is TestERC20 {
  constructor() TestERC20() {}

  receive() external payable {}

  event Deposit(address indexed dst, uint256 wad);
  event Withdrawal(address indexed src, uint256 wad);

  function deposit() public payable {
    _mint(msg.sender, msg.value);
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint256 wad) public {
    require(balanceOf(msg.sender) >= wad);
    _burn(msg.sender, wad);
    payable(msg.sender).transfer(wad);
    emit Withdrawal(msg.sender, wad);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IBridgeToken} from "../nomad-xapps/interfaces/bridge/IBridgeToken.sol";
import {ConnextMessage} from "../nomad-xapps/contracts/connext/ConnextMessage.sol";

/**
 * @notice This token is ONLY useful for testing
 * @dev Anybody can mint as many tokens as they like
 * @dev Anybody can burn anyone else's tokens
 */
contract TestERC20 is IBridgeToken, ERC20 {
  constructor() ERC20("Test Token", "TEST") {
    _mint(msg.sender, 1000000 ether);
  }

  // ============ IBridgeToken functions ===============
  function initialize() external override {}

  function detailsHash() external view override returns (bytes32) {
    return ConnextMessage.formatDetailsHash(name(), symbol(), decimals());
  }

  function setDetailsHash(bytes32 _detailsHash) external override {}

  function setDetails(
    string calldata _name,
    string calldata _symbol,
    uint8 _decimals
  ) external override {}

  function transferOwnership(address _newOwner) external override {}

  // ============ Token functions ===============
  function balanceOf(address account) public view override(ERC20, IBridgeToken) returns (uint256) {
    return ERC20.balanceOf(account);
  }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    _burn(account, amount);
  }

  function symbol() public view override(ERC20, IBridgeToken) returns (string memory) {
    return ERC20.symbol();
  }

  function name() public view override(ERC20, IBridgeToken) returns (string memory) {
    return ERC20.name();
  }

  function decimals() public view override(ERC20, IBridgeToken) returns (uint8) {
    return ERC20.decimals();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IBridgeToken {
  function initialize() external;

  function name() external returns (string memory);

  function balanceOf(address _account) external view returns (uint256);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function detailsHash() external view returns (bytes32);

  function burn(address _from, uint256 _amnt) external;

  function mint(address _to, uint256 _amnt) external;

  function setDetailsHash(bytes32 _detailsHash) external;

  function setDetails(
    string calldata _name,
    string calldata _symbol,
    uint8 _decimals
  ) external;

  // inherited from ownable
  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

// TODO: replace with nomad import
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

library ConnextMessage {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Enums ============

  // WARNING: do NOT re-write the numbers / order
  // of message types in an upgrade;
  // will cause in-flight messages to be mis-interpreted
  enum Types {
    Invalid, // 0
    TokenId, // 1
    Message, // 2
    Transfer // 3
  }

  // ============ Structs ============

  // Tokens are identified by a TokenId:
  // domain - 4 byte chain ID of the chain from which the token originates
  // id - 32 byte identifier of the token address on the origin chain, in that chain's address format
  struct TokenId {
    uint32 domain;
    bytes32 id;
  }

  // ============ Constants ============

  uint256 private constant TOKEN_ID_LEN = 36; // 4 bytes domain + 32 bytes id
  uint256 private constant IDENTIFIER_LEN = 1;
  uint256 private constant TRANSFER_LEN = 129;
  // 1 byte identifier + 32 bytes recipient + 32 bytes amount + 32 bytes detailsHash + 32 bytes external hash

  // ============ Modifiers ============

  /**
   * @notice Asserts a message is of type `_t`
   * @param _view The message
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Internal Functions: Validation ============

  /**
   * @notice Checks that Action is valid type
   * @param _action The action
   * @return TRUE if action is valid
   */
  function isValidAction(bytes29 _action) internal pure returns (bool) {
    return isTransfer(_action);
  }

  /**
   * @notice Checks that the message is of the specified type
   * @param _type the type to check for
   * @param _action The message
   * @return True if the message is of the specified type
   */
  function isType(bytes29 _action, Types _type) internal pure returns (bool) {
    return actionType(_action) == uint8(_type) && messageType(_action) == _type;
  }

  /**
   * @notice Checks that the message is of type Transfer
   * @param _action The message
   * @return True if the message is of type Transfer
   */
  function isTransfer(bytes29 _action) internal pure returns (bool) {
    return isType(_action, Types.Transfer);
  }

  /**
   * @notice Checks that view is a valid message length
   * @param _view The bytes string
   * @return TRUE if message is valid
   */
  function isValidMessageLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    return _len == TOKEN_ID_LEN + TRANSFER_LEN;
  }

  /**
   * @notice Asserts that the message is of type Message
   * @param _view The message
   * @return The message
   */
  function mustBeMessage(bytes29 _view) internal pure returns (bytes29) {
    return tryAsMessage(_view).assertValid();
  }

  // ============ Internal Functions: Formatting ============

  /**
   * @notice Formats an action message
   * @param _tokenId The token ID
   * @param _action The action
   * @return The formatted message
   */
  function formatMessage(bytes29 _tokenId, bytes29 _action)
    internal
    view
    typeAssert(_tokenId, Types.TokenId)
    returns (bytes memory)
  {
    require(isValidAction(_action), "!action");
    bytes29[] memory _views = new bytes29[](2);
    _views[0] = _tokenId;
    _views[1] = _action;
    return TypedMemView.join(_views);
  }

  /**
   * @notice Formats Transfer
   * @param _to The recipient address as bytes32
   * @param _amnt The transfer amount
   * @param _detailsHash The token details hash
   * @param _transferId Unique identifier for transfer
   * @return
   */
  function formatTransfer(
    bytes32 _to,
    uint256 _amnt,
    bytes32 _detailsHash,
    bytes32 _transferId
  ) internal pure returns (bytes29) {
    return
      abi.encodePacked(Types.Transfer, _to, _amnt, _detailsHash, _transferId).ref(0).castTo(uint40(Types.Transfer));
  }

  /**
   * @notice Serializes a Token ID struct
   * @param _tokenId The token id struct
   * @return The formatted Token ID
   */
  function formatTokenId(TokenId memory _tokenId) internal pure returns (bytes29) {
    return formatTokenId(_tokenId.domain, _tokenId.id);
  }

  /**
   * @notice Creates a serialized Token ID from components
   * @param _domain The domain
   * @param _id The ID
   * @return The formatted Token ID
   */
  function formatTokenId(uint32 _domain, bytes32 _id) internal pure returns (bytes29) {
    return abi.encodePacked(_domain, _id).ref(0).castTo(uint40(Types.TokenId));
  }

  /**
   * @notice Formats the keccak256 hash of the token details
   * Token Details Format:
   *      length of name cast to bytes - 32 bytes
   *      name - x bytes (variable)
   *      length of symbol cast to bytes - 32 bytes
   *      symbol - x bytes (variable)
   *      decimals - 1 byte
   * @param _name The name
   * @param _symbol The symbol
   * @param _decimals The decimals
   * @return The Details message
   */
  function formatDetailsHash(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(bytes(_name).length, _name, bytes(_symbol).length, _symbol, _decimals));
  }

  /**
   * @notice Converts to a Message
   * @param _message The message
   * @return The newly typed message
   */
  function tryAsMessage(bytes29 _message) internal pure returns (bytes29) {
    if (isValidMessageLength(_message)) {
      return _message.castTo(uint40(Types.Message));
    }
    return TypedMemView.nullView();
  }

  // ============ Internal Functions: Parsing msg ============

  /**
   * @notice Returns the type of the message
   * @param _view The message
   * @return The type of the message
   */
  function messageType(bytes29 _view) internal pure returns (Types) {
    return Types(uint8(_view.typeOf()));
  }

  /**
   * @notice Retrieves the token ID from a Message
   * @param _message The message
   * @return The ID
   */
  function tokenId(bytes29 _message) internal pure typeAssert(_message, Types.Message) returns (bytes29) {
    return _message.slice(0, TOKEN_ID_LEN, uint40(Types.TokenId));
  }

  /**
   * @notice Retrieves the action data from a Message
   * @param _message The message
   * @return The action
   */
  function action(bytes29 _message) internal pure typeAssert(_message, Types.Message) returns (bytes29) {
    uint256 _actionLen = _message.len() - TOKEN_ID_LEN;
    uint40 _type = uint40(msgType(_message));
    return _message.slice(TOKEN_ID_LEN, _actionLen, _type);
  }

  // ============ Internal Functions: Parsing tokenId ============

  /**
   * @notice Retrieves the domain from a TokenID
   * @param _tokenId The message
   * @return The domain
   */
  function domain(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (uint32) {
    return uint32(_tokenId.indexUint(0, 4));
  }

  /**
   * @notice Retrieves the ID from a TokenID
   * @param _tokenId The message
   * @return The ID
   */
  function id(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (bytes32) {
    // before = 4 bytes domain
    return _tokenId.index(4, 32);
  }

  /**
   * @notice Retrieves the EVM ID
   * @param _tokenId The message
   * @return The EVM ID
   */
  function evmId(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (address) {
    // before = 4 bytes domain + 12 bytes empty to trim for address
    return _tokenId.indexAddress(16);
  }

  // ============ Internal Functions: Parsing action ============

  /**
   * @notice Retrieves the action identifier from message
   * @param _message The action
   * @return The message type
   */
  function msgType(bytes29 _message) internal pure returns (uint8) {
    return uint8(_message.indexUint(TOKEN_ID_LEN, 1));
  }

  /**
   * @notice Retrieves the identifier from action
   * @param _action The action
   * @return The action type
   */
  function actionType(bytes29 _action) internal pure returns (uint8) {
    return uint8(_action.indexUint(0, 1));
  }

  /**
   * @notice Retrieves the recipient from a Transfer
   * @param _transferAction The message
   * @return The recipient address as bytes32
   */
  function recipient(bytes29 _transferAction) internal pure returns (bytes32) {
    // before = 1 byte identifier
    return _transferAction.index(1, 32);
  }

  /**
   * @notice Retrieves the EVM Recipient from a Transfer
   * @param _transferAction The message
   * @return The EVM Recipient
   */
  function evmRecipient(bytes29 _transferAction) internal pure returns (address) {
    // before = 1 byte identifier + 12 bytes empty to trim for address = 13 bytes
    return _transferAction.indexAddress(13);
  }

  /**
   * @notice Retrieves the amount from a Transfer
   * @param _transferAction The message
   * @return The amount
   */
  function amnt(bytes29 _transferAction) internal pure returns (uint256) {
    // before = 1 byte identifier + 32 bytes ID = 33 bytes
    return _transferAction.indexUint(33, 32);
  }

  /**
   * @notice Retrieves the unique identifier from a Transfer
   * @param _transferAction The message
   * @return The amount
   */
  function transferId(bytes29 _transferAction) internal pure returns (bytes32) {
    // before = 1 byte identifier + 32 bytes ID + 32 bytes amount + 32 bytes detailsHash = 97 bytes
    return _transferAction.index(97, 32);
  }

  /**
   * @notice Retrieves the detailsHash from a Transfer
   * @param _transferAction The message
   * @return The detailsHash
   */
  function detailsHash(bytes29 _transferAction) internal pure returns (bytes32) {
    // before = 1 byte identifier + 32 bytes ID + 32 bytes amount = 65 bytes
    return _transferAction.index(65, 32);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.11;

library TypedMemView {
  // Why does this exist?
  // the solidity `bytes memory` type has a few weaknesses.
  // 1. You can't index ranges effectively
  // 2. You can't slice without copying
  // 3. The underlying data may represent any type
  // 4. Solidity never deallocates memory, and memory costs grow
  //    superlinearly

  // By using a memory view instead of a `bytes memory` we get the following
  // advantages:
  // 1. Slices are done on the stack, by manipulating the pointer
  // 2. We can index arbitrary ranges and quickly convert them to stack types
  // 3. We can insert type info into the pointer, and typecheck at runtime

  // This makes `TypedMemView` a useful tool for efficient zero-copy
  // algorithms.

  // Why bytes29?
  // We want to avoid confusion between views, digests, and other common
  // types so we chose a large and uncommonly used odd number of bytes
  //
  // Note that while bytes are left-aligned in a word, integers and addresses
  // are right-aligned. This means when working in assembly we have to
  // account for the 3 unused bytes on the righthand side
  //
  // First 5 bytes are a type flag.
  // - ff_ffff_fffe is reserved for unknown type.
  // - ff_ffff_ffff is reserved for invalid types/errors.
  // next 12 are memory address
  // next 12 are len
  // bottom 3 bytes are empty

  // Assumptions:
  // - non-modification of memory.
  // - No Solidity updates
  // - - wrt free mem point
  // - - wrt bytes representation in memory
  // - - wrt memory addressing in general

  // Usage:
  // - create type constants
  // - use `assertType` for runtime type assertions
  // - - unfortunately we can't do this at compile time yet :(
  // - recommended: implement modifiers that perform type checking
  // - - e.g.
  // - - `uint40 constant MY_TYPE = 3;`
  // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
  // - instantiate a typed view from a bytearray using `ref`
  // - use `index` to inspect the contents of the view
  // - use `slice` to create smaller views into the same memory
  // - - `slice` can increase the offset
  // - - `slice can decrease the length`
  // - - must specify the output type of `slice`
  // - - `slice` will return a null view if you try to overrun
  // - - make sure to explicitly check for this with `notNull` or `assertType`
  // - use `equal` for typed comparisons.

  // The null view
  bytes29 public constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
  uint8 constant TWELVE_BYTES = 96;

  /**
   * @notice      Returns the encoded hex character that represents the lower 4 bits of the argument.
   * @param _b    The byte
   * @return      char - The encoded hex character
   */
  function nibbleHex(uint8 _b) internal pure returns (uint8 char) {
    // This can probably be done more efficiently, but it's only in error
    // paths, so we don't really care :)
    uint8 _nibble = _b | 0xf0; // set top 4, keep bottom 4
    if (_nibble == 0xf0) {
      return 0x30;
    } // 0
    if (_nibble == 0xf1) {
      return 0x31;
    } // 1
    if (_nibble == 0xf2) {
      return 0x32;
    } // 2
    if (_nibble == 0xf3) {
      return 0x33;
    } // 3
    if (_nibble == 0xf4) {
      return 0x34;
    } // 4
    if (_nibble == 0xf5) {
      return 0x35;
    } // 5
    if (_nibble == 0xf6) {
      return 0x36;
    } // 6
    if (_nibble == 0xf7) {
      return 0x37;
    } // 7
    if (_nibble == 0xf8) {
      return 0x38;
    } // 8
    if (_nibble == 0xf9) {
      return 0x39;
    } // 9
    if (_nibble == 0xfa) {
      return 0x61;
    } // a
    if (_nibble == 0xfb) {
      return 0x62;
    } // b
    if (_nibble == 0xfc) {
      return 0x63;
    } // c
    if (_nibble == 0xfd) {
      return 0x64;
    } // d
    if (_nibble == 0xfe) {
      return 0x65;
    } // e
    if (_nibble == 0xff) {
      return 0x66;
    } // f
  }

  /**
   * @notice      Returns a uint16 containing the hex-encoded byte.
   * @param _b    The byte
   * @return      encoded - The hex-encoded byte
   */
  function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
    encoded |= nibbleHex(_b >> 4); // top 4 bits
    encoded <<= 8;
    encoded |= nibbleHex(_b); // lower 4 bits
  }

  /**
   * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
   *              `second` contains the encoded lower 16 bytes.
   *
   * @param _b    The 32 bytes as uint256
   * @return      first - The top 16 bytes
   * @return      second - The bottom 16 bytes
   */
  function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
    for (uint8 i = 31; i > 15; ) {
      uint8 _byte = uint8(_b >> (i * 8));
      first |= byteHex(_byte);
      if (i != 16) {
        first <<= 16;
      }
      unchecked {
        i -= 1;
      }
    }

    // abusing underflow here =_=
    for (uint8 i = 15; i < 255; ) {
      uint8 _byte = uint8(_b >> (i * 8));
      second |= byteHex(_byte);
      if (i != 0) {
        second <<= 16;
      }
      unchecked {
        i -= 1;
      }
    }
  }

  /**
   * @notice          Changes the endianness of a uint256.
   * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
   * @param _b        The unsigned integer to reverse
   * @return          v - The reversed value
   */
  function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
    v = _b;

    // swap bytes
    v =
      ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
      ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    // swap 2-byte long pairs
    v =
      ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
      ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    // swap 4-byte long pairs
    v =
      ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
      ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
    // swap 8-byte long pairs
    v =
      ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
      ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
  }

  /**
   * @notice      Create a mask with the highest `_len` bits set.
   * @param _len  The length
   * @return      mask - The mask
   */
  function leftMask(uint8 _len) private pure returns (uint256 mask) {
    // ugly. redo without assembly?
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mask := sar(sub(_len, 1), 0x8000000000000000000000000000000000000000000000000000000000000000)
    }
  }

  /**
   * @notice      Return the null view.
   * @return      bytes29 - The null view
   */
  function nullView() internal pure returns (bytes29) {
    return NULL;
  }

  /**
   * @notice      Check if the view is null.
   * @return      bool - True if the view is null
   */
  function isNull(bytes29 memView) internal pure returns (bool) {
    return memView == NULL;
  }

  /**
   * @notice      Check if the view is not null.
   * @return      bool - True if the view is not null
   */
  function notNull(bytes29 memView) internal pure returns (bool) {
    return !isNull(memView);
  }

  /**
   * @notice          Check if the view is of a valid type and points to a valid location
   *                  in memory.
   * @dev             We perform this check by examining solidity's unallocated memory
   *                  pointer and ensuring that the view's upper bound is less than that.
   * @param memView   The view
   * @return          ret - True if the view is valid
   */
  function isValid(bytes29 memView) internal pure returns (bool ret) {
    if (typeOf(memView) == 0xffffffffff) {
      return false;
    }
    uint256 _end = end(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ret := not(gt(_end, mload(0x40)))
    }
  }

  /**
   * @notice          Require that a typed memory view be valid.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @return          bytes29 - The validated view
   */
  function assertValid(bytes29 memView) internal pure returns (bytes29) {
    require(isValid(memView), "Validity assertion failed");
    return memView;
  }

  /**
   * @notice          Return true if the memview is of the expected type. Otherwise false.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bool - True if the memview is of the expected type
   */
  function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
    return typeOf(memView) == _expected;
  }

  /**
   * @notice          Require that a typed memory view has a specific type.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bytes29 - The view with validated type
   */
  function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
    if (!isType(memView, _expected)) {
      (, uint256 g) = encodeHex(uint256(typeOf(memView)));
      (, uint256 e) = encodeHex(uint256(_expected));
      string memory err = string(
        abi.encodePacked("Type assertion failed. Got 0x", uint80(g), ". Expected 0x", uint80(e))
      );
      revert(err);
    }
    return memView;
  }

  /**
   * @notice          Return an identical view with a different type.
   * @param memView   The view
   * @param _newType  The new type
   * @return          newView - The new view with the specified type
   */
  function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
    // then | in the new type
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // shift off the top 5 bytes
      newView := or(newView, shr(40, shl(40, memView)))
      newView := or(newView, shl(216, _newType))
    }
  }

  /**
   * @notice          Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function unsafeBuildUnchecked(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) private pure returns (bytes29 newView) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      newView := shl(96, or(newView, _type)) // insert type
      newView := shl(96, or(newView, _loc)) // insert loc
      newView := shl(24, or(newView, _len)) // empty bottom 3 bytes
    }
  }

  /**
   * @notice          Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function build(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) internal pure returns (bytes29 newView) {
    uint256 _end = _loc + _len;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      if gt(_end, mload(0x40)) {
        _end := 0
      }
    }
    if (_end == 0) {
      return NULL;
    }
    newView = unsafeBuildUnchecked(_type, _loc, _len);
  }

  /**
   * @notice          Instantiate a memory view from a byte array.
   * @dev             Note that due to Solidity memory representation, it is not possible to
   *                  implement a deref, as the `bytes` type stores its len in memory.
   * @param arr       The byte array
   * @param newType   The type
   * @return          bytes29 - The memory view
   */
  function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
    uint256 _len = arr.length;

    uint256 _loc;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _loc := add(arr, 0x20) // our view is of the data, not the struct
    }

    return build(newType, _loc, _len);
  }

  /**
   * @notice          Return the associated type information.
   * @param memView   The memory view
   * @return          _type - The type associated with the view
   */
  function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 216 == 256 - 40
      _type := shr(216, memView) // shift out lower 24 bytes
    }
  }

  /**
   * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the 5-byte type flag is equal
   */
  function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (left ^ right) >> (2 * TWELVE_BYTES) == 0;
  }

  /**
   * @notice          Return the memory address of the underlying bytes.
   * @param memView   The view
   * @return          _loc - The memory address
   */
  function loc(bytes29 memView) internal pure returns (uint96 _loc) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
      _loc := and(shr(120, memView), _mask)
    }
  }

  /**
   * @notice          The number of memory words this memory view occupies, rounded up.
   * @param memView   The view
   * @return          uint256 - The number of memory words
   */
  function words(bytes29 memView) internal pure returns (uint256) {
    return (uint256(len(memView)) + 32) / 32;
  }

  /**
   * @notice          The in-memory footprint of a fresh copy of the view.
   * @param memView   The view
   * @return          uint256 - The in-memory footprint of a fresh copy of the view.
   */
  function footprint(bytes29 memView) internal pure returns (uint256) {
    return words(memView) * 32;
  }

  /**
   * @notice          The number of bytes of the view.
   * @param memView   The view
   * @return          _len - The length of the view
   */
  function len(bytes29 memView) internal pure returns (uint96 _len) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _len := and(shr(24, memView), _mask)
    }
  }

  /**
   * @notice          Returns the endpoint of `memView`.
   * @param memView   The view
   * @return          uint256 - The endpoint of `memView`
   */
  function end(bytes29 memView) internal pure returns (uint256) {
    unchecked {
      return loc(memView) + len(memView);
    }
  }

  /**
   * @notice          Safe slicing without memory modification.
   * @param memView   The view
   * @param _index    The start index
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function slice(
    bytes29 memView,
    uint256 _index,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    uint256 _loc = loc(memView);

    // Ensure it doesn't overrun the view
    if (_loc + _index + _len > end(memView)) {
      return NULL;
    }

    _loc = _loc + _index;
    return build(newType, _loc, _len);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function prefix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, 0, _len, newType);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the last `_len` byte.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function postfix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, uint256(len(memView)) - _len, _len, newType);
  }

  /**
   * @notice          Construct an error message for an indexing overrun.
   * @param _loc      The memory address
   * @param _len      The length
   * @param _index    The index
   * @param _slice    The slice where the overrun occurred
   * @return          err - The err
   */
  function indexErrOverrun(
    uint256 _loc,
    uint256 _len,
    uint256 _index,
    uint256 _slice
  ) internal pure returns (string memory err) {
    (, uint256 a) = encodeHex(_loc);
    (, uint256 b) = encodeHex(_len);
    (, uint256 c) = encodeHex(_index);
    (, uint256 d) = encodeHex(_slice);
    err = string(
      abi.encodePacked(
        "TypedMemView/index - Overran the view. Slice is at 0x",
        uint48(a),
        " with length 0x",
        uint48(b),
        ". Attempted to index at offset 0x",
        uint48(c),
        " with length 0x",
        uint48(d),
        "."
      )
    );
  }

  /**
   * @notice          Load up to 32 bytes from the view onto the stack.
   * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
   *                  This can be immediately cast to a smaller fixed-length byte array.
   *                  To automatically cast to an integer, use `indexUint`.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The 32 byte result
   */
  function index(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (bytes32 result) {
    if (_bytes == 0) {
      return bytes32(0);
    }
    if (_index + _bytes > len(memView)) {
      revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
    }
    require(_bytes <= 32, "TypedMemView/index - Attempted to index more than 32 bytes");

    uint8 bitLength;
    unchecked {
      bitLength = _bytes * 8;
    }
    uint256 _loc = loc(memView);
    uint256 _mask = leftMask(bitLength);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      result := and(mload(add(_loc, _index)), _mask)
    }
  }

  /**
   * @notice          Parse an unsigned integer from the view at `_index`.
   * @dev             Requires that the view have >= `_bytes` bytes following that index.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
  }

  /**
   * @notice          Parse an unsigned integer from LE bytes.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexLEUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return reverseUint256(uint256(index(memView, _index, _bytes)));
  }

  /**
   * @notice          Parse an address from the view at `_index`. Requires that the view have >= 20 bytes
   *                  following that index.
   * @param memView   The view
   * @param _index    The index
   * @return          address - The address
   */
  function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
    return address(uint160(indexUint(memView, _index, 20)));
  }

  /**
   * @notice          Return the keccak256 hash of the underlying memory
   * @param memView   The view
   * @return          digest - The keccak256 hash of the underlying memory
   */
  function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      digest := keccak256(_loc, _len)
    }
  }

  /**
   * @notice          Return the sha2 digest of the underlying memory.
   * @dev             We explicitly deallocate memory afterwards.
   * @param memView   The view
   * @return          digest - The sha2 hash of the underlying memory
   */
  function sha2(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      digest := mload(ptr)
    }
  }

  /**
   * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
   * @param memView   The pre-image
   * @return          digest - the Digest
   */
  function hash160(bytes29 memView) internal view returns (bytes20 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2
      pop(staticcall(gas(), 3, ptr, 0x20, ptr, 0x20)) // rmd160
      digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
    }
  }

  /**
   * @notice          Implements bitcoin's hash256 (double sha2)
   * @param memView   A view of the preimage
   * @return          digest - the Digest
   */
  function hash256(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
      digest := mload(ptr)
    }
  }

  /**
   * @notice          Return true if the underlying memory is equal. Else false.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the underlying memory is equal
   */
  function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
  }

  /**
   * @notice          Return false if the underlying memory is equal. Else true.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - False if the underlying memory is equal
   */
  function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !untypedEqual(left, right);
  }

  /**
   * @notice          Compares type equality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are the same
   */
  function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
    return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
  }

  /**
   * @notice          Compares type inequality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are not the same
   */
  function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !equal(left, right);
  }

  /**
   * @notice          Copy the view to a location, return an unsafe memory reference
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memView   The view
   * @param _newLoc   The new location
   * @return          written - the unsafe memory reference
   */
  function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
    require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
    require(isValid(memView), "TypedMemView/copyTo - Invalid pointer deref");
    uint256 _len = len(memView);
    uint256 _oldLoc = loc(memView);

    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _newLoc) {
        revert(0x60, 0x20) // empty revert message
      }

      // use the identity precompile to copy
      // guaranteed not to fail, so pop the success
      pop(staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len))
    }

    written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
  }

  /**
   * @notice          Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to
   *                  the new memory
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param memView   The view
   * @return          ret - The view pointing to the new memory
   */
  function clone(bytes29 memView) internal view returns (bytes memory ret) {
    uint256 ptr;
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
      ret := ptr
    }
    unchecked {
      unsafeCopyTo(memView, ptr + 0x20);
    }
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
      mstore(ptr, _len) // write len of new array (in bytes)
    }
  }

  /**
   * @notice          Join the views in memory, return an unsafe reference to the memory.
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memViews  The views
   * @return          unsafeView - The conjoined view pointing to the new memory
   */
  function unsafeJoin(bytes29[] memory memViews, uint256 _location) private view returns (bytes29 unsafeView) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _location) {
        revert(0x60, 0x20) // empty revert message
      }
    }

    uint256 _offset = 0;
    for (uint256 i = 0; i < memViews.length; i++) {
      bytes29 memView = memViews[i];
      unchecked {
        unsafeCopyTo(memView, _location + _offset);
        _offset += len(memView);
      }
    }
    unsafeView = unsafeBuildUnchecked(0, _location, _offset);
  }

  /**
   * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The keccak256 digest
   */
  function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return keccak(unsafeJoin(memViews, ptr));
  }

  /**
   * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The sha256 digest
   */
  function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return sha2(unsafeJoin(memViews, ptr));
  }

  /**
   * @notice          copies all views, joins them into a new bytearray.
   * @param memViews  The views
   * @return          ret - The new byte array
   */
  function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }

    bytes29 _newView;
    unchecked {
      _newView = unsafeJoin(memViews, ptr + 0x20);
    }
    uint256 _written = len(_newView);
    uint256 _footprint = footprint(_newView);

    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // store the legnth
      mstore(ptr, _written)
      // new pointer is old + 0x20 + the footprint of the body
      mstore(0x40, add(add(ptr, _footprint), 0x20))
      ret := ptr
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Nomad Contracts ============
import {ConnextMessage} from "./ConnextMessage.sol";
import {XAppConnectionClient} from "../XAppConnectionClient.sol";
import {Encoding} from "./Encoding.sol";
import {TypeCasts} from "../../../nomad-core/contracts/XAppConnectionManager.sol";
import {UpgradeBeaconProxy} from "../../../nomad-core/contracts/upgrade/UpgradeBeaconProxy.sol";
// ============ Interfaces ============
import {ITokenRegistry} from "../../interfaces/bridge/ITokenRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IBridgeToken} from "../../interfaces/bridge/IBridgeToken.sol";
// ============ External Contracts ============
// import {TypedMemView} from "@summa-tx/memview-sol/contracts/TypedMemView.sol";
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title TokenRegistry
 * @notice manages a registry of token contracts on this chain
 * -
 * We sort token types as "representation token" or "locally originating token".
 * Locally originating - a token contract that was originally deployed on the local chain
 * Representation (repr) - a token that was originally deployed on some other chain
 * -
 * When the BridgeRouter handles an incoming message, it determines whether the
 * transfer is for an asset of local origin. If not, it checks for an existing
 * representation contract. If no such representation exists, it deploys a new
 * representation contract. It then stores the relationship in the
 * "reprToCanonical" and "canonicalToRepr" mappings to ensure we can always
 * perform a lookup in either direction
 * Note that locally originating tokens should NEVER be represented in these lookup tables.
 */
contract TokenRegistry is Initializable, XAppConnectionClient, ITokenRegistry {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using ConnextMessage for bytes29;

  // ============ Public Storage ============
  uint32 private _local;

  // UpgradeBeacon from which new token proxies will get their implementation
  address public tokenBeacon;
  // local representation token address => token ID
  mapping(address => ConnextMessage.TokenId) public representationToCanonical;
  // hash of the tightly-packed TokenId => local representation token address
  // If the token is of local origin, this MUST map to address(0).
  mapping(bytes32 => address) public canonicalToRepresentation;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ============ Events ============

  /**
   * @notice emitted when a representation token contract is deployed
   * @param domain the domain of the chain where the canonical asset is deployed
   * @param id the bytes32 address of the canonical token contract
   * @param representation the address of the newly locally deployed representation contract
   */
  event TokenDeployed(uint32 indexed domain, bytes32 indexed id, address indexed representation);

  // ======== Initializer =========
  function setLocalDomain(uint32 domain) public {
    _local = domain;
  }

  function initialize(address _tokenBeacon, address _xAppConnectionManager) public initializer {
    tokenBeacon = _tokenBeacon;
    __XAppConnectionClient_initialize(_xAppConnectionManager);
  }

  // ======== TokenId & Address Lookup for Representation Tokens =========

  /**
   * @notice Look up the canonical token ID for a representation token
   * @param _representation the address of the representation contract
   * @return _domain the domain of the canonical version.
   * @return _id the identifier of the canonical version in its domain.
   */
  function getCanonicalTokenId(address _representation) external view returns (uint32 _domain, bytes32 _id) {
    ConnextMessage.TokenId memory _canonical = representationToCanonical[_representation];
    _domain = _canonical.domain;
    _id = _canonical.id;
  }

  /**
   * @notice Look up the representation address for a canonical token
   * @param _domain the domain of the canonical version.
   * @param _id the identifier of the canonical version in its domain.
   * @return _representation the address of the representation contract
   */
  function getRepresentationAddress(uint32 _domain, bytes32 _id) public view returns (address _representation) {
    bytes29 _tokenId = ConnextMessage.formatTokenId(_domain, _id);
    bytes32 _idHash = _tokenId.keccak();
    _representation = canonicalToRepresentation[_idHash];
  }

  // ======== External: Deploying Representation Tokens =========

  /**
   * @notice Get the address of the local token for the provided tokenId;
   * if the token is remote and no local representation exists, deploy the representation contract
   * @param _domain the token's native domain
   * @param _id the token's id on its native domain
   * @return _local the address of the local token contract
   */
  function ensureLocalToken(uint32 _domain, bytes32 _id) external override returns (address _local) {
    _local = getLocalAddress(_domain, _id);
    if (_local == address(0)) {
      // Representation does not exist yet;
      // deploy representation contract
      _local = _deployToken(_domain, _id);
    }
  }

  // ======== External: Enrolling Representation Tokens =========

  /**
   * @notice Enroll a custom token. This allows projects to work with
   * governance to specify a custom representation.
   * @dev This is done by inserting the custom representation into the token
   * lookup tables. It is permissioned to the owner (governance) and can
   * potentially break token representations. It must be used with extreme
   * caution.
   * After the token is inserted, new mint instructions will be sent to the
   * custom token. The default representation (and old custom representations)
   * may still be burnt. Until all users have explicitly called migrate, both
   * representations will continue to exist.
   * The custom representation MUST be trusted, and MUST allow the router to
   * both mint AND burn tokens at will.
   * @param _domain the domain of the canonical Token to enroll
   * @param _id the bytes32 ID pf the canonical of the Token to enroll
   * @param _custom the address of the custom implementation to use.
   */
  function enrollCustom(
    uint32 _domain,
    bytes32 _id,
    address _custom
  ) external override {
    // update mappings with custom token
    _setRepresentationToCanonical(_domain, _id, _custom);
    _setCanonicalToRepresentation(_domain, _id, _custom);
  }

  // ======== Match Old Representation Tokens =========

  /**
   * @notice Returns the current representation contract
   * for the same canonical token as the old representation contract
   * @dev If _oldRepr is not a representation, this will error.
   * @param _oldRepr The address of the old representation token
   * @return _currentRepr The address of the current representation token
   */
  function oldReprToCurrentRepr(address _oldRepr) external view override returns (address _currentRepr) {
    // get the canonical token ID for the old representation contract
    ConnextMessage.TokenId memory _tokenId = representationToCanonical[_oldRepr];
    require(_tokenId.domain != 0, "!repr");
    // get the current primary representation for the same canonical token ID
    _currentRepr = getRepresentationAddress(_tokenId.domain, _tokenId.id);
  }

  // ======== TokenId & Address Lookup for ALL Local Tokens (Representation AND Canonical) =========

  /**
   * @notice Return tokenId for a local token address
   * @param _local the local address of the token contract (representation or canonical)
   * @return _domain canonical domain
   * @return _id canonical identifier on that domain
   */
  function getTokenId(address _local) external view override returns (uint32 _domain, bytes32 _id) {
    ConnextMessage.TokenId memory _tokenId = representationToCanonical[_local];
    if (_tokenId.domain == 0) {
      _domain = _localDomain();
      _id = TypeCasts.addressToBytes32(_local);
    } else {
      _domain = _tokenId.domain;
      _id = _tokenId.id;
    }
  }

  /**
   * @notice Looks up the local address corresponding to a domain/id pair.
   * @dev If the token is local, it will return the local address.
   * If the token is non-local and no local representation exists, this
   * will return `address(0)`.
   * @param _domain the domain of the canonical version.
   * @param _id the identifier of the canonical version in its domain.
   * @return _local the local address of the token contract (representation or canonical)
   */
  function getLocalAddress(uint32 _domain, address _id) external view returns (address _local) {
    _local = getLocalAddress(_domain, TypeCasts.addressToBytes32(_id));
  }

  /**
   * @notice Looks up the local address corresponding to a domain/id pair.
   * @dev If the token is local, it will return the local address.
   * If the token is non-local and no local representation exists, this
   * will return `address(0)`.
   * @param _domain the domain of the canonical version.
   * @param _id the identifier of the canonical version in its domain.
   * @return _local the local address of the token contract (representation or canonical)
   */
  function getLocalAddress(uint32 _domain, bytes32 _id) public view override returns (address _local) {
    if (_domain == _localDomain()) {
      // Token is of local origin
      _local = TypeCasts.bytes32ToAddress(_id);
    } else {
      // Token is a representation of a token of remote origin
      _local = getRepresentationAddress(_domain, _id);
    }
  }

  /**
   * @notice Return the local token contract for the
   * canonical tokenId; revert if there is no local token
   * @param _domain the token's native domain
   * @param _id the token's id on its native domain
   * @return the local IERC20 token contract
   */
  function mustHaveLocalToken(uint32 _domain, bytes32 _id) external view override returns (IERC20) {
    address _local = getLocalAddress(_domain, _id);
    require(_local != address(0), "!token");
    return IERC20(_local);
  }

  /**
   * @notice Determine if token is of local origin
   * @return TRUE if token is locally originating
   */
  function isLocalOrigin(address _token) public view override returns (bool) {
    // If the contract WAS deployed by the TokenRegistry,
    // it will be stored in this mapping.
    // If so, it IS NOT of local origin
    if (representationToCanonical[_token].domain != 0) {
      return false;
    }
    // If the contract WAS NOT deployed by the TokenRegistry,
    // and the contract exists, then it IS of local origin
    // Return true if code exists at _addr
    uint256 _codeSize;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      _codeSize := extcodesize(_token)
    }
    return _codeSize != 0;
  }

  // ======== Internal Functions =========

  /**
   * @notice Set the primary representation for a given canonical
   * @param _domain the domain of the canonical token
   * @param _id the bytes32 ID pf the canonical of the token
   * @param _representation the address of the representation token
   */
  function _setRepresentationToCanonical(
    uint32 _domain,
    bytes32 _id,
    address _representation
  ) internal {
    representationToCanonical[_representation].domain = _domain;
    representationToCanonical[_representation].id = _id;
  }

  /**
   * @notice Set the canonical token for a given representation
   * @param _domain the domain of the canonical token
   * @param _id the bytes32 ID pf the canonical of the token
   * @param _representation the address of the representation token
   */
  function _setCanonicalToRepresentation(
    uint32 _domain,
    bytes32 _id,
    address _representation
  ) internal {
    bytes29 _tokenId = ConnextMessage.formatTokenId(_domain, _id);
    bytes32 _idHash = _tokenId.keccak();
    canonicalToRepresentation[_idHash] = _representation;
  }

  /**
   * @notice Deploy and initialize a new token contract
   * @dev Each token contract is a proxy which
   * points to the token upgrade beacon
   * @return _token the address of the token contract
   */
  function _deployToken(uint32 _domain, bytes32 _id) internal returns (address _token) {
    // deploy and initialize the token contract
    _token = address(new UpgradeBeaconProxy(tokenBeacon, ""));
    // initialize the token separately from the
    IBridgeToken(_token).initialize();
    // set the default token name & symbol
    (string memory _name, string memory _symbol) = _defaultDetails(_domain, _id);
    IBridgeToken(_token).setDetails(_name, _symbol, 18);
    // transfer ownership to bridgeRouter
    IBridgeToken(_token).transferOwnership(owner());
    // store token in mappings
    _setCanonicalToRepresentation(_domain, _id, _token);
    _setRepresentationToCanonical(_domain, _id, _token);
    // emit event upon deploying new token
    emit TokenDeployed(_domain, _id, _token);
  }

  /**
   * @notice Get default name and details for a token
   * Sets name to "nomad.[domain].[id]"
   * and symbol to
   * @param _domain the domain of the canonical token
   * @param _id the bytes32 ID pf the canonical of the token
   */
  function _defaultDetails(uint32 _domain, bytes32 _id)
    internal
    pure
    returns (string memory _name, string memory _symbol)
  {
    // get the first and second half of the token ID
    (, uint256 _secondHalfId) = Encoding.encodeHex(uint256(_id));
    // encode the default token name: "[decimal domain].[hex 4 bytes of ID]"
    _name = string(
      abi.encodePacked(
        Encoding.decimalUint32(_domain), // 10
        ".", // 1
        uint32(_secondHalfId) // 4
      )
    );
    // allocate the memory for a new 32-byte string
    _symbol = new string(10 + 1 + 4);
    assembly {
      mstore(add(_symbol, 0x20), mload(add(_name, 0x20)))
    }
  }

  /**
   * @dev explicit override for compiler inheritance
   * @dev explicit override for compiler inheritance
   * @return domain of chain on which the contract is deployed
   */
  function _localDomain() internal view override(XAppConnectionClient) returns (uint32) {
    // return XAppConnectionClient._localDomain();
    return _local;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ External Imports ============
// import {Home} from "../../../../nomad-core-sol/contracts/Home.sol";
import {Home} from "../../nomad-core/contracts/Home.sol";
import {XAppConnectionManager} from "../../nomad-core/contracts/XAppConnectionManager.sol";

// TODO: refactor proposed ownable to be one basic + one router/asset
import {ProposedOwnableUpgradeable} from "../../ProposedOwnableUpgradeable.sol";

abstract contract XAppConnectionClient is ProposedOwnableUpgradeable {
  // ============ Mutable Storage ============

  XAppConnectionManager public xAppConnectionManager;
  uint256[49] private __GAP; // gap for upgrade safety

  // ============ Modifiers ============

  /**
   * @notice Only accept messages from an Nomad Replica contract
   */
  modifier onlyReplica() {
    require(_isReplica(msg.sender), "!replica");
    _;
  }

  // ======== Initializer =========

  function __XAppConnectionClient_initialize(address _xAppConnectionManager) internal initializer {
    xAppConnectionManager = XAppConnectionManager(_xAppConnectionManager);
    __ProposedOwnable_init();
  }

  // ============ External functions ============

  /**
   * @notice Modify the contract the xApp uses to validate Replica contracts
   * @param _xAppConnectionManager The address of the xAppConnectionManager contract
   */
  function setXAppConnectionManager(address _xAppConnectionManager) external onlyOwner {
    xAppConnectionManager = XAppConnectionManager(_xAppConnectionManager);
  }

  // ============ Internal functions ============

  /**
   * @notice Get the local Home contract from the xAppConnectionManager
   * @return The local Home contract
   */
  function _home() internal view returns (Home) {
    return xAppConnectionManager.home();
  }

  /**
   * @notice Determine whether _potentialReplcia is an enrolled Replica from the xAppConnectionManager
   * @return True if _potentialReplica is an enrolled Replica
   */
  function _isReplica(address _potentialReplica) internal view returns (bool) {
    return xAppConnectionManager.isReplica(_potentialReplica);
  }

  /**
   * @notice Get the local domain from the xAppConnectionManager
   * @return The local domain
   */
  function _localDomain() internal view virtual returns (uint32) {
    return xAppConnectionManager.localDomain();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

library Encoding {
  // ============ Constants ============

  bytes private constant NIBBLE_LOOKUP = "0123456789abcdef";

  // ============ Internal Functions ============

  /**
   * @notice Encode a uint32 in its DECIMAL representation, with leading
   * zeroes.
   * @param _num The number to encode
   * @return _encoded The encoded number, suitable for use in abi.
   * encodePacked
   */
  function decimalUint32(uint32 _num) internal pure returns (uint80 _encoded) {
    uint80 ASCII_0 = 0x30;
    // all over/underflows are impossible
    // this will ALWAYS produce 10 decimal characters
    for (uint8 i = 0; i < 10; i += 1) {
      _encoded |= ((_num % 10) + ASCII_0) << (i * 8);
      _num = _num / 10;
    }
  }

  /**
   * @notice Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
   * `second` contains the encoded lower 16 bytes.
   * @param _bytes The 32 bytes as uint256
   * @return _firstHalf The top 16 bytes
   * @return _secondHalf The bottom 16 bytes
   */
  function encodeHex(uint256 _bytes) internal pure returns (uint256 _firstHalf, uint256 _secondHalf) {
    for (uint8 i = 31; i > 15; i -= 1) {
      uint8 _b = uint8(_bytes >> (i * 8));
      _firstHalf |= _byteHex(_b);
      if (i != 16) {
        _firstHalf <<= 16;
      }
    }
    // abusing underflow here =_=
    unchecked {
      for (uint8 i = 15; i < 255; i -= 1) {
        uint8 _b = uint8(_bytes >> (i * 8));
        _secondHalf |= _byteHex(_b);
        if (i != 0) {
          _secondHalf <<= 16;
        }
      }
    }
  }

  /**
   * @notice Returns the encoded hex character that represents the lower 4 bits of the argument.
   * @param _byte The byte
   * @return _char The encoded hex character
   */
  function _nibbleHex(uint8 _byte) private pure returns (uint8 _char) {
    uint8 _nibble = _byte & 0x0f; // keep bottom 4, 0 top 4
    _char = uint8(NIBBLE_LOOKUP[_nibble]);
  }

  /**
   * @notice Returns a uint16 containing the hex-encoded byte.
   * @param _byte The byte
   * @return _encoded The hex-encoded byte
   */
  function _byteHex(uint8 _byte) private pure returns (uint16 _encoded) {
    _encoded |= _nibbleHex(_byte >> 4); // top 4 bits
    _encoded <<= 8;
    _encoded |= _nibbleHex(_byte); // lower 4 bits
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Home} from "./Home.sol";
import {Replica} from "./Replica.sol";
import {TypeCasts} from "../libs/TypeCasts.sol";
// ============ External Imports ============
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title XAppConnectionManager
 * @author Illusory Systems Inc.
 * @notice Manages a registry of local Replica contracts
 * for remote Home domains. Accepts Watcher signatures
 * to un-enroll Replicas attached to fraudulent remote Homes
 */
contract XAppConnectionManager is Ownable {
  // ============ Public Storage ============

  // Home contract
  Home public home;
  // local Replica address => remote Home domain
  mapping(address => uint32) public replicaToDomain;
  // remote Home domain => local Replica address
  mapping(uint32 => address) public domainToReplica;
  // watcher address => replica remote domain => has/doesn't have permission
  mapping(address => mapping(uint32 => bool)) private watcherPermissions;

  // ============ Events ============

  /**
   * @notice Emitted when a new Replica is enrolled / added
   * @param domain the remote domain of the Home contract for the Replica
   * @param replica the address of the Replica
   */
  event ReplicaEnrolled(uint32 indexed domain, address replica);

  /**
   * @notice Emitted when a new Replica is un-enrolled / removed
   * @param domain the remote domain of the Home contract for the Replica
   * @param replica the address of the Replica
   */
  event ReplicaUnenrolled(uint32 indexed domain, address replica);

  /**
   * @notice Emitted when Watcher permissions are changed
   * @param domain the remote domain of the Home contract for the Replica
   * @param watcher the address of the Watcher
   * @param access TRUE if the Watcher was given permissions, FALSE if permissions were removed
   */
  event WatcherPermissionSet(uint32 indexed domain, address watcher, bool access);

  // ============ Modifiers ============

  modifier onlyReplica() {
    require(isReplica(msg.sender), "!replica");
    _;
  }

  // ============ Constructor ============

  // solhint-disable-next-line no-empty-blocks
  constructor() Ownable() {}

  // ============ External Functions ============

  /**
   * @notice Un-Enroll a replica contract
   * in the case that fraud was detected on the Home
   * @dev in the future, if fraud occurs on the Home contract,
   * the Watcher will submit their signature directly to the Home
   * and it can be relayed to all remote chains to un-enroll the Replicas
   * @param _domain the remote domain of the Home contract for the Replica
   * @param _updater the address of the Updater for the Home contract (also stored on Replica)
   * @param _signature signature of watcher on (domain, replica address, updater address)
   */
  function unenrollReplica(
    uint32 _domain,
    bytes32 _updater,
    bytes memory _signature
  ) external {
    // ensure that the replica is currently set
    address _replica = domainToReplica[_domain];
    require(_replica != address(0), "!replica exists");
    // ensure that the signature is on the proper updater
    require(Replica(_replica).updater() == TypeCasts.bytes32ToAddress(_updater), "!current updater");
    // get the watcher address from the signature
    // and ensure that the watcher has permission to un-enroll this replica
    address _watcher = _recoverWatcherFromSig(_domain, TypeCasts.addressToBytes32(_replica), _updater, _signature);
    require(watcherPermissions[_watcher][_domain], "!valid watcher");
    // remove the replica from mappings
    _unenrollReplica(_replica);
  }

  /**
   * @notice Set the address of the local Home contract
   * @param _home the address of the local Home contract
   */
  function setHome(address _home) external onlyOwner {
    home = Home(_home);
  }

  /**
   * @notice Allow Owner to enroll Replica contract
   * @param _replica the address of the Replica
   * @param _domain the remote domain of the Home contract for the Replica
   */
  function ownerEnrollReplica(address _replica, uint32 _domain) external onlyOwner {
    // un-enroll any existing replica
    _unenrollReplica(_replica);
    // add replica and domain to two-way mapping
    replicaToDomain[_replica] = _domain;
    domainToReplica[_domain] = _replica;
    emit ReplicaEnrolled(_domain, _replica);
  }

  /**
   * @notice Allow Owner to un-enroll Replica contract
   * @param _replica the address of the Replica
   */
  function ownerUnenrollReplica(address _replica) external onlyOwner {
    _unenrollReplica(_replica);
  }

  /**
   * @notice Allow Owner to set Watcher permissions for a Replica
   * @param _watcher the address of the Watcher
   * @param _domain the remote domain of the Home contract for the Replica
   * @param _access TRUE to give the Watcher permissions, FALSE to remove permissions
   */
  function setWatcherPermission(
    address _watcher,
    uint32 _domain,
    bool _access
  ) external onlyOwner {
    watcherPermissions[_watcher][_domain] = _access;
    emit WatcherPermissionSet(_domain, _watcher, _access);
  }

  /**
   * @notice Query local domain from Home
   * @return local domain
   */
  function localDomain() external view returns (uint32) {
    return home.localDomain();
  }

  /**
   * @notice Get access permissions for the watcher on the domain
   * @param _watcher the address of the watcher
   * @param _domain the domain to check for watcher permissions
   * @return TRUE iff _watcher has permission to un-enroll replicas on _domain
   */
  function watcherPermission(address _watcher, uint32 _domain) external view returns (bool) {
    return watcherPermissions[_watcher][_domain];
  }

  // ============ Public Functions ============

  /**
   * @notice Check whether _replica is enrolled
   * @param _replica the replica to check for enrollment
   * @return TRUE iff _replica is enrolled
   */
  function isReplica(address _replica) public view returns (bool) {
    return replicaToDomain[_replica] != 0;
  }

  // ============ Internal Functions ============

  /**
   * @notice Remove the replica from the two-way mappings
   * @param _replica replica to un-enroll
   */
  function _unenrollReplica(address _replica) internal {
    uint32 _currentDomain = replicaToDomain[_replica];
    domainToReplica[_currentDomain] = address(0);
    replicaToDomain[_replica] = 0;
    emit ReplicaUnenrolled(_currentDomain, _replica);
  }

  /**
   * @notice Get the Watcher address from the provided signature
   * @return address of watcher that signed
   */
  function _recoverWatcherFromSig(
    uint32 _domain,
    bytes32 _replica,
    bytes32 _updater,
    bytes memory _signature
  ) internal view returns (address) {
    bytes32 _homeDomainHash = Replica(TypeCasts.bytes32ToAddress(_replica)).homeDomainHash();
    bytes32 _digest = keccak256(abi.encodePacked(_homeDomainHash, _domain, _updater));
    _digest = ECDSA.toEthSignedMessageHash(_digest);
    return ECDSA.recover(_digest, _signature);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

// ============ External Imports ============
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title UpgradeBeaconProxy
 * @notice
 * Proxy contract which delegates all logic, including initialization,
 * to an implementation contract.
 * The implementation contract is stored within an Upgrade Beacon contract;
 * the implementation contract can be changed by performing an upgrade on the Upgrade Beacon contract.
 * The Upgrade Beacon contract for this Proxy is immutably specified at deployment.
 * @dev This implementation combines the gas savings of keeping the UpgradeBeacon address outside of contract storage
 * found in 0age's implementation:
 * https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/proxies/smart-wallet/UpgradeBeaconProxyV1.sol
 * With the added safety checks that the UpgradeBeacon and implementation are contracts at time of deployment
 * found in OpenZeppelin's implementation:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/beacon/BeaconProxy.sol
 */
contract UpgradeBeaconProxy {
  // ============ Immutables ============

  // Upgrade Beacon address is immutable (therefore not kept in contract storage)
  address private immutable upgradeBeacon;

  // ============ Constructor ============

  /**
   * @notice Validate that the Upgrade Beacon is a contract, then set its
   * address immutably within this contract.
   * Validate that the implementation is also a contract,
   * Then call the initialization function defined at the implementation.
   * The deployment will revert and pass along the
   * revert reason if the initialization function reverts.
   * @param _upgradeBeacon Address of the Upgrade Beacon to be stored immutably in the contract
   * @param _initializationCalldata Calldata supplied when calling the initialization function
   */
  constructor(address _upgradeBeacon, bytes memory _initializationCalldata) payable {
    // Validate the Upgrade Beacon is a contract
    require(Address.isContract(_upgradeBeacon), "beacon !contract");
    // set the Upgrade Beacon
    upgradeBeacon = _upgradeBeacon;
    // Validate the implementation is a contract
    address _implementation = _getImplementation(_upgradeBeacon);
    require(Address.isContract(_implementation), "beacon implementation !contract");
    // Call the initialization function on the implementation
    if (_initializationCalldata.length > 0) {
      _initialize(_implementation, _initializationCalldata);
    }
  }

  // ============ External Functions ============

  /**
   * @notice Forwards all calls with data to _fallback()
   * No public functions are declared on the contract, so all calls hit fallback
   */
  fallback() external payable {
    _fallback();
  }

  /**
   * @notice Forwards all calls with no data to _fallback()
   */
  receive() external payable {
    _fallback();
  }

  // ============ Private Functions ============

  /**
   * @notice Call the initialization function on the implementation
   * Used at deployment to initialize the proxy
   * based on the logic for initialization defined at the implementation
   * @param _implementation - Contract to which the initalization is delegated
   * @param _initializationCalldata - Calldata supplied when calling the initialization function
   */
  function _initialize(address _implementation, bytes memory _initializationCalldata) private {
    // Delegatecall into the implementation, supplying initialization calldata.
    (bool _ok, ) = _implementation.delegatecall(_initializationCalldata);
    // Revert and include revert data if delegatecall to implementation reverts.
    if (!_ok) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  /**
   * @notice Delegates function calls to the implementation contract returned by the Upgrade Beacon
   */
  function _fallback() private {
    _delegate(_getImplementation());
  }

  /**
   * @notice Delegate function execution to the implementation contract
   * @dev This is a low level function that doesn't return to its internal
   * call site. It will return whatever is returned by the implementation to the
   * external caller, reverting and returning the revert data if implementation
   * reverts.
   * @param _implementation - Address to which the function execution is delegated
   */
  function _delegate(address _implementation) private {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())
      // Delegatecall to the implementation, supplying calldata and gas.
      // Out and outsize are set to zero - instead, use the return buffer.
      let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
      // Copy the returned data from the return buffer.
      returndatacopy(0, 0, returndatasize())
      switch result
      // Delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @notice Call the Upgrade Beacon to get the current implementation contract address
   * @return _implementation Address of the current implementation.
   */
  function _getImplementation() private view returns (address _implementation) {
    _implementation = _getImplementation(upgradeBeacon);
  }

  /**
   * @notice Call the Upgrade Beacon to get the current implementation contract address
   * @dev _upgradeBeacon is passed as a parameter so that
   * we can also use this function in the constructor,
   * where we can't access immutable variables.
   * @param _upgradeBeacon Address of the UpgradeBeacon storing the current implementation
   * @return _implementation Address of the current implementation.
   */
  function _getImplementation(address _upgradeBeacon) private view returns (address _implementation) {
    // Get the current implementation address from the upgrade beacon.
    (bool _ok, bytes memory _returnData) = _upgradeBeacon.staticcall("");
    // Revert and pass along revert message if call to upgrade beacon reverts.
    require(_ok, string(_returnData));
    // Set the implementation to the address returned from the upgrade beacon.
    _implementation = abi.decode(_returnData, (address));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {IBridgeToken} from "./IBridgeToken.sol";

// ============ External Imports ============
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenRegistry {
  function isLocalOrigin(address _token) external view returns (bool);

  function ensureLocalToken(uint32 _domain, bytes32 _id) external returns (address _local);

  function mustHaveLocalToken(uint32 _domain, bytes32 _id) external view returns (IERC20);

  function getLocalAddress(uint32 _domain, bytes32 _id) external view returns (address _local);

  function getTokenId(address _token) external view returns (uint32, bytes32);

  function enrollCustom(
    uint32 _domain,
    bytes32 _id,
    address _custom
  ) external;

  function oldReprToCurrentRepr(address _oldRepr) external view returns (address _currentRepr);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Version0} from "./Version0.sol";
import {NomadBase} from "./NomadBase.sol";
import {QueueLib} from "../libs/Queue.sol";
import {MerkleLib} from "../libs/Merkle.sol";
import {Message} from "../libs/Message.sol";
import {MerkleTreeManager} from "./Merkle.sol";
import {QueueManager} from "./Queue.sol";
import {IUpdaterManager} from "../interfaces/IUpdaterManager.sol";
// ============ External Imports ============
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Home
 * @author Illusory Systems Inc.
 * @notice Accepts messages to be dispatched to remote chains,
 * constructs a Merkle tree of the messages,
 * and accepts signatures from a bonded Updater
 * which notarize the Merkle tree roots.
 * Accepts submissions of fraudulent signatures
 * by the Updater and slashes the Updater in this case.
 */
contract Home is Version0, QueueManager, MerkleTreeManager, NomadBase {
  // ============ Libraries ============

  using QueueLib for QueueLib.Queue;
  using MerkleLib for MerkleLib.Tree;

  // ============ Constants ============

  // Maximum bytes per message = 2 KiB
  // (somewhat arbitrarily set to begin)
  uint256 public constant MAX_MESSAGE_BODY_BYTES = 2 * 2**10;

  // ============ Public Storage Variables ============

  // domain => next available nonce for the domain
  mapping(uint32 => uint32) public nonces;
  // contract responsible for Updater bonding, slashing and rotation
  IUpdaterManager public updaterManager;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[48] private __GAP;

  // ============ Events ============

  /**
   * @notice Emitted when a new message is dispatched via Nomad
   * @param leafIndex Index of message's leaf in merkle tree
   * @param destinationAndNonce Destination and destination-specific
   * nonce combined in single field ((destination << 32) & nonce)
   * @param messageHash Hash of message; the leaf inserted to the Merkle tree for the message
   * @param committedRoot the latest notarized root submitted in the last signed Update
   * @param message Raw bytes of message
   */
  event Dispatch(
    bytes32 indexed messageHash,
    uint256 indexed leafIndex,
    uint64 indexed destinationAndNonce,
    bytes32 committedRoot,
    bytes message
  );

  /**
   * @notice Emitted when proof of an improper update is submitted,
   * which sets the contract to FAILED state
   * @param oldRoot Old root of the improper update
   * @param newRoot New root of the improper update
   * @param signature Signature on `oldRoot` and `newRoot
   */
  event ImproperUpdate(bytes32 oldRoot, bytes32 newRoot, bytes signature);

  /**
   * @notice Emitted when the Updater is slashed
   * (should be paired with ImproperUpdater or DoubleUpdate event)
   * @param updater The address of the updater
   * @param reporter The address of the entity that reported the updater misbehavior
   */
  event UpdaterSlashed(address indexed updater, address indexed reporter);

  /**
   * @notice Emitted when the UpdaterManager contract is changed
   * @param updaterManager The address of the new updaterManager
   */
  event NewUpdaterManager(address updaterManager);

  // ============ Constructor ============

  constructor(uint32 _localDomain) NomadBase(_localDomain) {} // solhint-disable-line no-empty-blocks

  // ============ Initializer ============

  function initialize(IUpdaterManager _updaterManager) public initializer {
    // initialize queue, set Updater Manager, and initialize
    __QueueManager_initialize();
    _setUpdaterManager(_updaterManager);
    __NomadBase_initialize(updaterManager.updater());
  }

  // ============ Modifiers ============

  /**
   * @notice Ensures that function is called by the UpdaterManager contract
   */
  modifier onlyUpdaterManager() {
    require(msg.sender == address(updaterManager), "!updaterManager");
    _;
  }

  // ============ External: Updater & UpdaterManager Configuration  ============

  /**
   * @notice Set a new Updater
   * @param _updater the new Updater
   */
  function setUpdater(address _updater) external onlyUpdaterManager {
    _setUpdater(_updater);
  }

  /**
   * @notice Set a new UpdaterManager contract
   * @dev Home(s) will initially be initialized using a trusted UpdaterManager contract;
   * we will progressively decentralize by swapping the trusted contract with a new implementation
   * that implements Updater bonding & slashing, and rules for Updater selection & rotation
   * @param _updaterManager the new UpdaterManager contract
   */
  function setUpdaterManager(address _updaterManager) external onlyOwner {
    _setUpdaterManager(IUpdaterManager(_updaterManager));
  }

  // ============ External Functions  ============

  /**
   * @notice Dispatch the message it to the destination domain & recipient
   * @dev Format the message, insert its hash into Merkle tree,
   * enqueue the new Merkle root, and emit `Dispatch` event with message information.
   * @param _destinationDomain Domain of destination chain
   * @param _recipientAddress Address of recipient on destination chain as bytes32
   * @param _messageBody Raw bytes content of message
   */
  function dispatch(
    uint32 _destinationDomain,
    bytes32 _recipientAddress,
    bytes memory _messageBody
  ) external notFailed {
    require(_messageBody.length <= MAX_MESSAGE_BODY_BYTES, "msg too long");
    // get the next nonce for the destination domain, then increment it
    uint32 _nonce = nonces[_destinationDomain];
    nonces[_destinationDomain] = _nonce + 1;
    // format the message into packed bytes
    bytes memory _message = Message.formatMessage(
      localDomain,
      bytes32(uint256(uint160(msg.sender))),
      _nonce,
      _destinationDomain,
      _recipientAddress,
      _messageBody
    );
    // insert the hashed message into the Merkle tree
    bytes32 _messageHash = keccak256(_message);
    tree.insert(_messageHash);
    // enqueue the new Merkle root after inserting the message
    queue.enqueue(root());
    // Emit Dispatch event with message information
    // note: leafIndex is count() - 1 since new leaf has already been inserted
    emit Dispatch(_messageHash, count() - 1, _destinationAndNonce(_destinationDomain, _nonce), committedRoot, _message);
  }

  /**
   * @notice Submit a signature from the Updater "notarizing" a root,
   * which updates the Home contract's `committedRoot`,
   * and publishes the signature which will be relayed to Replica contracts
   * @dev emits Update event
   * @dev If _newRoot is not contained in the queue,
   * the Update is a fraudulent Improper Update, so
   * the Updater is slashed & Home is set to FAILED state
   * @param _committedRoot Current updated merkle root which the update is building off of
   * @param _newRoot New merkle root to update the contract state to
   * @param _signature Updater signature on `_committedRoot` and `_newRoot`
   */
  function update(
    bytes32 _committedRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) external notFailed {
    // check that the update is not fraudulent;
    // if fraud is detected, Updater is slashed & Home is set to FAILED state
    if (improperUpdate(_committedRoot, _newRoot, _signature)) return;
    // clear all of the intermediate roots contained in this update from the queue
    while (true) {
      bytes32 _next = queue.dequeue();
      if (_next == _newRoot) break;
    }
    // update the Home state with the latest signed root & emit event
    committedRoot = _newRoot;
    emit Update(localDomain, _committedRoot, _newRoot, _signature);
  }

  /**
   * @notice Suggest an update for the Updater to sign and submit.
   * @dev If queue is empty, null bytes returned for both
   * (No update is necessary because no messages have been dispatched since the last update)
   * @return _committedRoot Latest root signed by the Updater
   * @return _new Latest enqueued Merkle root
   */
  function suggestUpdate() external view returns (bytes32 _committedRoot, bytes32 _new) {
    if (queue.length() != 0) {
      _committedRoot = committedRoot;
      _new = queue.lastItem();
    }
  }

  // ============ Public Functions  ============

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   */
  function homeDomainHash() public view override returns (bytes32) {
    return _homeDomainHash(localDomain);
  }

  /**
   * @notice Check if an Update is an Improper Update;
   * if so, slash the Updater and set the contract to FAILED state.
   *
   * An Improper Update is an update building off of the Home's `committedRoot`
   * for which the `_newRoot` does not currently exist in the Home's queue.
   * This would mean that message(s) that were not truly
   * dispatched on Home were falsely included in the signed root.
   *
   * An Improper Update will only be accepted as valid by the Replica
   * If an Improper Update is attempted on Home,
   * the Updater will be slashed immediately.
   * If an Improper Update is submitted to the Replica,
   * it should be relayed to the Home contract using this function
   * in order to slash the Updater with an Improper Update.
   *
   * An Improper Update submitted to the Replica is only valid
   * while the `_oldRoot` is still equal to the `committedRoot` on Home;
   * if the `committedRoot` on Home has already been updated with a valid Update,
   * then the Updater should be slashed with a Double Update.
   * @dev Reverts (and doesn't slash updater) if signature is invalid or
   * update not current
   * @param _oldRoot Old merkle tree root (should equal home's committedRoot)
   * @param _newRoot New merkle tree root
   * @param _signature Updater signature on `_oldRoot` and `_newRoot`
   * @return TRUE if update was an Improper Update (implying Updater was slashed)
   */
  function improperUpdate(
    bytes32 _oldRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) public notFailed returns (bool) {
    require(_isUpdaterSignature(_oldRoot, _newRoot, _signature), "!updater sig");
    require(_oldRoot == committedRoot, "not a current update");
    // if the _newRoot is not currently contained in the queue,
    // slash the Updater and set the contract to FAILED state
    if (!queue.contains(_newRoot)) {
      _fail();
      emit ImproperUpdate(_oldRoot, _newRoot, _signature);
      return true;
    }
    // if the _newRoot is contained in the queue,
    // this is not an improper update
    return false;
  }

  // ============ Internal Functions  ============

  /**
   * @notice Set the UpdaterManager
   * @param _updaterManager Address of the UpdaterManager
   */
  function _setUpdaterManager(IUpdaterManager _updaterManager) internal {
    require(Address.isContract(address(_updaterManager)), "!contract updaterManager");
    updaterManager = IUpdaterManager(_updaterManager);
    emit NewUpdaterManager(address(_updaterManager));
  }

  /**
   * @notice Slash the Updater and set contract state to FAILED
   * @dev Called when fraud is proven (Improper Update or Double Update)
   */
  function _fail() internal override {
    // set contract to FAILED
    _setFailed();
    // slash Updater
    updaterManager.slashUpdater(payable(msg.sender));
    emit UpdaterSlashed(updater, msg.sender);
  }

  /**
   * @notice Internal utility function that combines
   * `_destination` and `_nonce`.
   * @dev Both destination and nonce should be less than 2^32 - 1
   * @param _destination Domain of destination chain
   * @param _nonce Current nonce for given destination chain
   * @return Returns (`_destination` << 32) & `_nonce`
   */
  function _destinationAndNonce(uint32 _destination, uint32 _nonce) internal pure returns (uint64) {
    return (uint64(_destination) << 32) | _nonce;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title ProposedOwnable
 * @notice Contract module which provides a basic access control mechanism,
 * where there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed via a two step process:
 * 1. Call `proposeOwner`
 * 2. Wait out the delay period
 * 3. Call `acceptOwner`
 *
 * @dev This module is used through inheritance. It will make available the
 * modifier `onlyOwner`, which can be applied to your functions to restrict
 * their use to the owner.
 *
 * @dev The majority of this code was taken from the openzeppelin Ownable
 * contract
 *
 */
abstract contract ProposedOwnableUpgradeable is Initializable {
  // ========== Custom Errors ===========

  error ProposedOwnableUpgradeable__onlyOwner_notOwner();
  error ProposedOwnableUpgradeable__onlyProposed_notProposedOwner();
  error ProposedOwnableUpgradeable__proposeRouterOwnershipRenunciation_noOwnershipChange();
  error ProposedOwnableUpgradeable__renounceRouterOwnership_noOwnershipChange();
  error ProposedOwnableUpgradeable__renounceRouterOwnership_noProposal();
  error ProposedOwnableUpgradeable__renounceRouterOwnership_delayNotElapsed();
  error ProposedOwnableUpgradeable__proposeAssetOwnershipRenunciation_noOwnershipChange();
  error ProposedOwnableUpgradeable__renounceAssetOwnership_noOwnershipChange();
  error ProposedOwnableUpgradeable__renounceAssetOwnership_noProposal();
  error ProposedOwnableUpgradeable__renounceAssetOwnership_delayNotElapsed();
  error ProposedOwnableUpgradeable__proposeNewOwner_invalidProposal();
  error ProposedOwnableUpgradeable__proposeNewOwner_noOwnershipChange();
  error ProposedOwnableUpgradeable__renounceOwnership_noProposal();
  error ProposedOwnableUpgradeable__renounceOwnership_delayNotElapsed();
  error ProposedOwnableUpgradeable__renounceOwnership_invalidProposal();
  error ProposedOwnableUpgradeable__acceptProposedOwner_noOwnershipChange();
  error ProposedOwnableUpgradeable__acceptProposedOwner_delayNotElapsed();

  // ============ Properties ============

  address private _owner;

  address private _proposed;
  uint256 private _proposedOwnershipTimestamp;

  bool private _routerOwnershipRenounced;
  uint256 private _routerOwnershipTimestamp;

  bool private _assetOwnershipRenounced;
  uint256 private _assetOwnershipTimestamp;

  uint256 private constant _delay = 7 days;

  event RouterOwnershipRenunciationProposed(uint256 timestamp);

  event RouterOwnershipRenounced(bool renounced);

  event AssetOwnershipRenunciationProposed(uint256 timestamp);

  event AssetOwnershipRenounced(bool renounced);

  event OwnershipProposed(address indexed proposedOwner);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial
   */
  function __ProposedOwnable_init() internal onlyInitializing {
    __ProposedOwnable_init_unchained();
  }

  function __ProposedOwnable_init_unchained() internal onlyInitializing {
    _setOwner(msg.sender);
  }

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposed() public view virtual returns (address) {
    return _proposed;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposedTimestamp() public view virtual returns (uint256) {
    return _proposedOwnershipTimestamp;
  }

  /**
   * @notice Returns the timestamp when router ownership was last proposed to be renounced
   */
  function routerOwnershipTimestamp() public view virtual returns (uint256) {
    return _routerOwnershipTimestamp;
  }

  /**
   * @notice Returns the timestamp when asset ownership was last proposed to be renounced
   */
  function assetOwnershipTimestamp() public view virtual returns (uint256) {
    return _assetOwnershipTimestamp;
  }

  /**
   * @notice Returns the delay period before a new owner can be accepted.
   */
  function delay() public view virtual returns (uint256) {
    return _delay;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (_owner != msg.sender) revert ProposedOwnableUpgradeable__onlyOwner_notOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyProposed() {
    if (_proposed != msg.sender) revert ProposedOwnableUpgradeable__onlyProposed_notProposedOwner();
    _;
  }

  /**
   * @notice Indicates if the ownership of the router whitelist has
   * been renounced
   */
  function isRouterOwnershipRenounced() public view returns (bool) {
    return _owner == address(0) || _routerOwnershipRenounced;
  }

  /**
   * @notice Indicates if the ownership of the router whitelist has
   * been renounced
   */
  function proposeRouterOwnershipRenunciation() public virtual onlyOwner {
    // Use contract as source of truth
    // Will fail if all ownership is renounced by modifier
    if (_routerOwnershipRenounced)
      revert ProposedOwnableUpgradeable__proposeRouterOwnershipRenunciation_noOwnershipChange();

    // Begin delay, emit event
    _setRouterOwnershipTimestamp();
  }

  /**
   * @notice Indicates if the ownership of the asset whitelist has
   * been renounced
   */
  function renounceRouterOwnership() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    if (_routerOwnershipRenounced) revert ProposedOwnableUpgradeable__renounceRouterOwnership_noOwnershipChange();

    // Ensure there has been a proposal cycle started
    if (_routerOwnershipTimestamp == 0) revert ProposedOwnableUpgradeable__renounceRouterOwnership_noProposal();

    // Delay has elapsed
    if ((block.timestamp - _routerOwnershipTimestamp) <= _delay)
      revert ProposedOwnableUpgradeable__renounceRouterOwnership_delayNotElapsed();

    // Set renounced, emit event, reset timestamp to 0
    _setRouterOwnership(true);
  }

  /**
   * @notice Indicates if the ownership of the asset whitelist has
   * been renounced
   */
  function isAssetOwnershipRenounced() public view returns (bool) {
    return _owner == address(0) || _assetOwnershipRenounced;
  }

  /**
   * @notice Indicates if the ownership of the asset whitelist has
   * been renounced
   */
  function proposeAssetOwnershipRenunciation() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    if (_assetOwnershipRenounced)
      revert ProposedOwnableUpgradeable__proposeAssetOwnershipRenunciation_noOwnershipChange();

    // Start cycle, emit event
    _setAssetOwnershipTimestamp();
  }

  /**
   * @notice Indicates if the ownership of the asset whitelist has
   * been renounced
   */
  function renounceAssetOwnership() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    if (_assetOwnershipRenounced) revert ProposedOwnableUpgradeable__renounceAssetOwnership_noOwnershipChange();

    // Ensure there has been a proposal cycle started
    if (_assetOwnershipTimestamp == 0) revert ProposedOwnableUpgradeable__renounceAssetOwnership_noProposal();

    // Ensure delay has elapsed
    if ((block.timestamp - _assetOwnershipTimestamp) <= _delay)
      revert ProposedOwnableUpgradeable__renounceAssetOwnership_delayNotElapsed();

    // Set ownership, reset timestamp, emit event
    _setAssetOwnership(true);
  }

  /**
   * @notice Indicates if the ownership has been renounced() by
   * checking if current owner is address(0)
   */
  function renounced() public view returns (bool) {
    return _owner == address(0);
  }

  /**
   * @notice Sets the timestamp for an owner to be proposed, and sets the
   * newly proposed owner as step 1 in a 2-step process
   */
  function proposeNewOwner(address newlyProposed) public virtual onlyOwner {
    // Contract as source of truth
    if (_proposed == newlyProposed && newlyProposed != address(0))
      revert ProposedOwnableUpgradeable__proposeNewOwner_invalidProposal();

    // Sanity check: reasonable proposal
    if (_owner == newlyProposed) revert ProposedOwnableUpgradeable__proposeNewOwner_noOwnershipChange();

    _setProposed(newlyProposed);
  }

  /**
   * @notice Renounces ownership of the contract after a delay
   */
  function renounceOwnership() public virtual onlyOwner {
    // Ensure there has been a proposal cycle started
    if (_proposedOwnershipTimestamp == 0) revert ProposedOwnableUpgradeable__renounceOwnership_noProposal();

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnableUpgradeable__renounceOwnership_delayNotElapsed();

    // Require proposed is set to 0
    if (_proposed != address(0)) revert ProposedOwnableUpgradeable__renounceOwnership_invalidProposal();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function acceptProposedOwner() public virtual onlyProposed {
    // Contract as source of truth
    if (_owner == _proposed) revert ProposedOwnableUpgradeable__acceptProposedOwner_noOwnershipChange();

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnableUpgradeable__acceptProposedOwner_delayNotElapsed();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  ////// INTERNAL //////

  function _setRouterOwnershipTimestamp() private {
    _routerOwnershipTimestamp = block.timestamp;
    emit RouterOwnershipRenunciationProposed(_routerOwnershipTimestamp);
  }

  function _setRouterOwnership(bool value) private {
    _routerOwnershipRenounced = value;
    _routerOwnershipTimestamp = 0;
    emit RouterOwnershipRenounced(value);
  }

  function _setAssetOwnershipTimestamp() private {
    _assetOwnershipTimestamp = block.timestamp;
    emit AssetOwnershipRenunciationProposed(_assetOwnershipTimestamp);
  }

  function _setAssetOwnership(bool value) private {
    _assetOwnershipRenounced = value;
    _assetOwnershipTimestamp = 0;
    emit AssetOwnershipRenounced(value);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    _proposedOwnershipTimestamp = 0;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(_proposed);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title Version0
 * @notice Version getter for contracts
 **/
contract Version0 {
  uint8 public constant VERSION = 0;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Message} from "../libs/Message.sol";
// ============ External Imports ============
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title NomadBase
 * @author Illusory Systems Inc.
 * @notice Shared utilities between Home and Replica.
 */
abstract contract NomadBase is Initializable, OwnableUpgradeable {
  // ============ Enums ============

  // States:
  //   0 - UnInitialized - before initialize function is called
  //   note: the contract is initialized at deploy time, so it should never be in this state
  //   1 - Active - as long as the contract has not become fraudulent
  //   2 - Failed - after a valid fraud proof has been submitted;
  //   contract will no longer accept updates or new messages
  enum States {
    UnInitialized,
    Active,
    Failed
  }

  // ============ Immutable Variables ============

  // Domain of chain on which the contract is deployed
  uint32 public immutable localDomain;

  // ============ Public Variables ============

  // Address of bonded Updater
  address public updater;
  // Current state of contract
  States public state;
  // The latest root that has been signed by the Updater
  bytes32 public committedRoot;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[47] private __GAP;

  // ============ Events ============

  /**
   * @notice Emitted when update is made on Home
   * or unconfirmed update root is submitted on Replica
   * @param homeDomain Domain of home contract
   * @param oldRoot Old merkle root
   * @param newRoot New merkle root
   * @param signature Updater's signature on `oldRoot` and `newRoot`
   */
  event Update(uint32 indexed homeDomain, bytes32 indexed oldRoot, bytes32 indexed newRoot, bytes signature);

  /**
   * @notice Emitted when proof of a double update is submitted,
   * which sets the contract to FAILED state
   * @param oldRoot Old root shared between two conflicting updates
   * @param newRoot Array containing two conflicting new roots
   * @param signature Signature on `oldRoot` and `newRoot`[0]
   * @param signature2 Signature on `oldRoot` and `newRoot`[1]
   */
  event DoubleUpdate(bytes32 oldRoot, bytes32[2] newRoot, bytes signature, bytes signature2);

  /**
   * @notice Emitted when Updater is rotated
   * @param oldUpdater The address of the old updater
   * @param newUpdater The address of the new updater
   */
  event NewUpdater(address oldUpdater, address newUpdater);

  // ============ Modifiers ============

  /**
   * @notice Ensures that contract state != FAILED when the function is called
   */
  modifier notFailed() {
    require(state != States.Failed, "failed state");
    _;
  }

  // ============ Constructor ============

  constructor(uint32 _localDomain) {
    localDomain = _localDomain;
  }

  // ============ Initializer ============

  function __NomadBase_initialize(address _updater) internal initializer {
    __Ownable_init();
    _setUpdater(_updater);
    state = States.Active;
  }

  // ============ External Functions ============

  /**
   * @notice Called by external agent. Checks that signatures on two sets of
   * roots are valid and that the new roots conflict with each other. If both
   * cases hold true, the contract is failed and a `DoubleUpdate` event is
   * emitted.
   * @dev When `fail()` is called on Home, updater is slashed.
   * @param _oldRoot Old root shared between two conflicting updates
   * @param _newRoot Array containing two conflicting new roots
   * @param _signature Signature on `_oldRoot` and `_newRoot`[0]
   * @param _signature2 Signature on `_oldRoot` and `_newRoot`[1]
   */
  function doubleUpdate(
    bytes32 _oldRoot,
    bytes32[2] calldata _newRoot,
    bytes calldata _signature,
    bytes calldata _signature2
  ) external notFailed {
    if (
      NomadBase._isUpdaterSignature(_oldRoot, _newRoot[0], _signature) &&
      NomadBase._isUpdaterSignature(_oldRoot, _newRoot[1], _signature2) &&
      _newRoot[0] != _newRoot[1]
    ) {
      _fail();
      emit DoubleUpdate(_oldRoot, _newRoot, _signature, _signature2);
    }
  }

  // ============ Public Functions ============

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   */
  function homeDomainHash() public view virtual returns (bytes32);

  // ============ Internal Functions ============

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   * @param _homeDomain the Home domain to hash
   */
  function _homeDomainHash(uint32 _homeDomain) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_homeDomain, "NOMAD"));
  }

  /**
   * @notice Set contract state to FAILED
   * @dev Called when a valid fraud proof is submitted
   */
  function _setFailed() internal {
    state = States.Failed;
  }

  /**
   * @notice Moves the contract into failed state
   * @dev Called when fraud is proven
   * (Double Update is submitted on Home or Replica,
   * or Improper Update is submitted on Home)
   */
  function _fail() internal virtual;

  /**
   * @notice Set the Updater
   * @param _newUpdater Address of the new Updater
   */
  function _setUpdater(address _newUpdater) internal {
    address _oldUpdater = updater;
    updater = _newUpdater;
    emit NewUpdater(_oldUpdater, _newUpdater);
  }

  /**
   * @notice Checks that signature was signed by Updater
   * @param _oldRoot Old merkle root
   * @param _newRoot New merkle root
   * @param _signature Signature on `_oldRoot` and `_newRoot`
   * @return TRUE iff signature is valid signed by updater
   **/
  function _isUpdaterSignature(
    bytes32 _oldRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) internal view returns (bool) {
    bytes32 _digest = keccak256(abi.encodePacked(homeDomainHash(), _oldRoot, _newRoot));
    _digest = ECDSA.toEthSignedMessageHash(_digest);
    return (ECDSA.recover(_digest, _signature) == updater);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title QueueLib
 * @author Illusory Systems Inc.
 * @notice Library containing queue struct and operations for queue used by
 * Home and Replica.
 **/
library QueueLib {
  /**
   * @notice Queue struct
   * @dev Internally keeps track of the `first` and `last` elements through
   * indices and a mapping of indices to enqueued elements.
   **/
  struct Queue {
    uint128 first;
    uint128 last;
    mapping(uint256 => bytes32) queue;
  }

  /**
   * @notice Initializes the queue
   * @dev Empty state denoted by _q.first > q._last. Queue initialized
   * with _q.first = 1 and _q.last = 0.
   **/
  function initialize(Queue storage _q) internal {
    if (_q.first == 0) {
      _q.first = 1;
    }
  }

  /**
   * @notice Enqueues a single new element
   * @param _item New element to be enqueued
   * @return _last Index of newly enqueued element
   **/
  function enqueue(Queue storage _q, bytes32 _item) internal returns (uint128 _last) {
    _last = _q.last + 1;
    _q.last = _last;
    if (_item != bytes32(0)) {
      // saves gas if we're queueing 0
      _q.queue[_last] = _item;
    }
  }

  /**
   * @notice Dequeues element at front of queue
   * @dev Removes dequeued element from storage
   * @return _item Dequeued element
   **/
  function dequeue(Queue storage _q) internal returns (bytes32 _item) {
    uint128 _last = _q.last;
    uint128 _first = _q.first;
    require(_length(_last, _first) != 0, "Empty");
    _item = _q.queue[_first];
    if (_item != bytes32(0)) {
      // saves gas if we're dequeuing 0
      delete _q.queue[_first];
    }
    _q.first = _first + 1;
  }

  /**
   * @notice Batch enqueues several elements
   * @param _items Array of elements to be enqueued
   * @return _last Index of last enqueued element
   **/
  function enqueue(Queue storage _q, bytes32[] memory _items) internal returns (uint128 _last) {
    _last = _q.last;
    for (uint256 i = 0; i < _items.length; i += 1) {
      _last += 1;
      bytes32 _item = _items[i];
      if (_item != bytes32(0)) {
        _q.queue[_last] = _item;
      }
    }
    _q.last = _last;
  }

  /**
   * @notice Batch dequeues `_number` elements
   * @dev Reverts if `_number` > queue length
   * @param _number Number of elements to dequeue
   * @return Array of dequeued elements
   **/
  function dequeue(Queue storage _q, uint256 _number) internal returns (bytes32[] memory) {
    uint128 _last = _q.last;
    uint128 _first = _q.first;
    // Cannot underflow unless state is corrupted
    require(_length(_last, _first) >= _number, "Insufficient");

    bytes32[] memory _items = new bytes32[](_number);

    for (uint256 i = 0; i < _number; i++) {
      _items[i] = _q.queue[_first];
      delete _q.queue[_first];
      _first++;
    }
    _q.first = _first;
    return _items;
  }

  /**
   * @notice Returns true if `_item` is in the queue and false if otherwise
   * @dev Linearly scans from _q.first to _q.last looking for `_item`
   * @param _item Item being searched for in queue
   * @return True if `_item` currently exists in queue, false if otherwise
   **/
  function contains(Queue storage _q, bytes32 _item) internal view returns (bool) {
    for (uint256 i = _q.first; i <= _q.last; i++) {
      if (_q.queue[i] == _item) {
        return true;
      }
    }
    return false;
  }

  /// @notice Returns last item in queue
  /// @dev Returns bytes32(0) if queue empty
  function lastItem(Queue storage _q) internal view returns (bytes32) {
    return _q.queue[_q.last];
  }

  /// @notice Returns element at front of queue without removing element
  /// @dev Reverts if queue is empty
  function peek(Queue storage _q) internal view returns (bytes32 _item) {
    require(!isEmpty(_q), "Empty");
    _item = _q.queue[_q.first];
  }

  /// @notice Returns true if queue is empty and false if otherwise
  function isEmpty(Queue storage _q) internal view returns (bool) {
    return _q.last < _q.first;
  }

  /// @notice Returns number of elements in queue
  function length(Queue storage _q) internal view returns (uint256) {
    uint128 _last = _q.last;
    uint128 _first = _q.first;
    // Cannot underflow unless state is corrupted
    return _length(_last, _first);
  }

  /// @notice Returns number of elements between `_last` and `_first` (used internally)
  function _length(uint128 _last, uint128 _first) internal pure returns (uint256) {
    return uint256(_last + 1 - _first);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// work based on eth2 deposit contract, which is used under CC0-1.0

/**
 * @title MerkleLib
 * @author Illusory Systems Inc.
 * @notice An incremental merkle tree modeled on the eth2 deposit contract.
 **/
library MerkleLib {
  uint256 internal constant TREE_DEPTH = 32;
  uint256 internal constant MAX_LEAVES = 2**TREE_DEPTH - 1;

  /**
   * @notice Struct representing incremental merkle tree. Contains current
   * branch and the number of inserted leaves in the tree.
   **/
  struct Tree {
    bytes32[TREE_DEPTH] branch;
    uint256 count;
  }

  /**
   * @notice Inserts `_node` into merkle tree
   * @dev Reverts if tree is full
   * @param _node Element to insert into tree
   **/
  function insert(Tree storage _tree, bytes32 _node) internal {
    require(_tree.count < MAX_LEAVES, "merkle tree full");

    _tree.count += 1;
    uint256 size = _tree.count;
    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      if ((size & 1) == 1) {
        _tree.branch[i] = _node;
        return;
      }
      _node = keccak256(abi.encodePacked(_tree.branch[i], _node));
      size /= 2;
    }
    // As the loop should always end prematurely with the `return` statement,
    // this code should be unreachable. We assert `false` just to be safe.
    assert(false);
  }

  /**
   * @notice Calculates and returns`_tree`'s current root given array of zero
   * hashes
   * @param _zeroes Array of zero hashes
   * @return _current Calculated root of `_tree`
   **/
  function rootWithCtx(Tree storage _tree, bytes32[TREE_DEPTH] memory _zeroes)
    internal
    view
    returns (bytes32 _current)
  {
    uint256 _index = _tree.count;

    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      uint256 _ithBit = (_index >> i) & 0x01;
      bytes32 _next = _tree.branch[i];
      if (_ithBit == 1) {
        _current = keccak256(abi.encodePacked(_next, _current));
      } else {
        _current = keccak256(abi.encodePacked(_current, _zeroes[i]));
      }
    }
  }

  /// @notice Calculates and returns`_tree`'s current root
  function root(Tree storage _tree) internal view returns (bytes32) {
    return rootWithCtx(_tree, zeroHashes());
  }

  /// @notice Returns array of TREE_DEPTH zero hashes
  /// @return _zeroes Array of TREE_DEPTH zero hashes
  function zeroHashes() internal pure returns (bytes32[TREE_DEPTH] memory _zeroes) {
    _zeroes[0] = Z_0;
    _zeroes[1] = Z_1;
    _zeroes[2] = Z_2;
    _zeroes[3] = Z_3;
    _zeroes[4] = Z_4;
    _zeroes[5] = Z_5;
    _zeroes[6] = Z_6;
    _zeroes[7] = Z_7;
    _zeroes[8] = Z_8;
    _zeroes[9] = Z_9;
    _zeroes[10] = Z_10;
    _zeroes[11] = Z_11;
    _zeroes[12] = Z_12;
    _zeroes[13] = Z_13;
    _zeroes[14] = Z_14;
    _zeroes[15] = Z_15;
    _zeroes[16] = Z_16;
    _zeroes[17] = Z_17;
    _zeroes[18] = Z_18;
    _zeroes[19] = Z_19;
    _zeroes[20] = Z_20;
    _zeroes[21] = Z_21;
    _zeroes[22] = Z_22;
    _zeroes[23] = Z_23;
    _zeroes[24] = Z_24;
    _zeroes[25] = Z_25;
    _zeroes[26] = Z_26;
    _zeroes[27] = Z_27;
    _zeroes[28] = Z_28;
    _zeroes[29] = Z_29;
    _zeroes[30] = Z_30;
    _zeroes[31] = Z_31;
  }

  /**
   * @notice Calculates and returns the merkle root for the given leaf
   * `_item`, a merkle branch, and the index of `_item` in the tree.
   * @param _item Merkle leaf
   * @param _branch Merkle proof
   * @param _index Index of `_item` in tree
   * @return _current Calculated merkle root
   **/
  function branchRoot(
    bytes32 _item,
    bytes32[TREE_DEPTH] memory _branch,
    uint256 _index
  ) internal pure returns (bytes32 _current) {
    _current = _item;

    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      uint256 _ithBit = (_index >> i) & 0x01;
      bytes32 _next = _branch[i];
      if (_ithBit == 1) {
        _current = keccak256(abi.encodePacked(_next, _current));
      } else {
        _current = keccak256(abi.encodePacked(_current, _next));
      }
    }
  }

  // keccak256 zero hashes
  bytes32 internal constant Z_0 = hex"0000000000000000000000000000000000000000000000000000000000000000";
  bytes32 internal constant Z_1 = hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";
  bytes32 internal constant Z_2 = hex"b4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30";
  bytes32 internal constant Z_3 = hex"21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85";
  bytes32 internal constant Z_4 = hex"e58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344";
  bytes32 internal constant Z_5 = hex"0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d";
  bytes32 internal constant Z_6 = hex"887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968";
  bytes32 internal constant Z_7 = hex"ffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83";
  bytes32 internal constant Z_8 = hex"9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af";
  bytes32 internal constant Z_9 = hex"cefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0";
  bytes32 internal constant Z_10 = hex"f9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5";
  bytes32 internal constant Z_11 = hex"f8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892";
  bytes32 internal constant Z_12 = hex"3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c";
  bytes32 internal constant Z_13 = hex"c1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb";
  bytes32 internal constant Z_14 = hex"5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc";
  bytes32 internal constant Z_15 = hex"da7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2";
  bytes32 internal constant Z_16 = hex"2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f";
  bytes32 internal constant Z_17 = hex"e1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a";
  bytes32 internal constant Z_18 = hex"5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0";
  bytes32 internal constant Z_19 = hex"b46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0";
  bytes32 internal constant Z_20 = hex"c65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2";
  bytes32 internal constant Z_21 = hex"f4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9";
  bytes32 internal constant Z_22 = hex"5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377";
  bytes32 internal constant Z_23 = hex"4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652";
  bytes32 internal constant Z_24 = hex"cdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef";
  bytes32 internal constant Z_25 = hex"0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d";
  bytes32 internal constant Z_26 = hex"b8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0";
  bytes32 internal constant Z_27 = hex"838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e";
  bytes32 internal constant Z_28 = hex"662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e";
  bytes32 internal constant Z_29 = hex"388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322";
  bytes32 internal constant Z_30 = hex"93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735";
  bytes32 internal constant Z_31 = hex"8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9";
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// import "@summa-tx/memview-sol/contracts/TypedMemView.sol";

import "./TypedMemView.sol";

import {TypeCasts} from "./TypeCasts.sol";

/**
 * @title Message Library
 * @author Illusory Systems Inc.
 * @notice Library for formatted messages used by Home and Replica.
 **/
library Message {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // Number of bytes in formatted message before `body` field
  uint256 internal constant PREFIX_LENGTH = 76;

  /**
   * @notice Returns formatted (packed) message with provided fields
   * @param _originDomain Domain of home chain
   * @param _sender Address of sender as bytes32
   * @param _nonce Destination-specific nonce
   * @param _destinationDomain Domain of destination chain
   * @param _recipient Address of recipient on destination chain as bytes32
   * @param _messageBody Raw bytes of message body
   * @return Formatted message
   **/
  function formatMessage(
    uint32 _originDomain,
    bytes32 _sender,
    uint32 _nonce,
    uint32 _destinationDomain,
    bytes32 _recipient,
    bytes memory _messageBody
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(_originDomain, _sender, _nonce, _destinationDomain, _recipient, _messageBody);
  }

  /**
   * @notice Returns leaf of formatted message with provided fields.
   * @param _origin Domain of home chain
   * @param _sender Address of sender as bytes32
   * @param _nonce Destination-specific nonce number
   * @param _destination Domain of destination chain
   * @param _recipient Address of recipient on destination chain as bytes32
   * @param _body Raw bytes of message body
   * @return Leaf (hash) of formatted message
   **/
  function messageHash(
    uint32 _origin,
    bytes32 _sender,
    uint32 _nonce,
    uint32 _destination,
    bytes32 _recipient,
    bytes memory _body
  ) internal pure returns (bytes32) {
    return keccak256(formatMessage(_origin, _sender, _nonce, _destination, _recipient, _body));
  }

  /// @notice Returns message's origin field
  function origin(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(0, 4));
  }

  /// @notice Returns message's sender field
  function sender(bytes29 _message) internal pure returns (bytes32) {
    return _message.index(4, 32);
  }

  /// @notice Returns message's nonce field
  function nonce(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(36, 4));
  }

  /// @notice Returns message's destination field
  function destination(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(40, 4));
  }

  /// @notice Returns message's recipient field as bytes32
  function recipient(bytes29 _message) internal pure returns (bytes32) {
    return _message.index(44, 32);
  }

  /// @notice Returns message's recipient field as an address
  function recipientAddress(bytes29 _message) internal pure returns (address) {
    return TypeCasts.bytes32ToAddress(recipient(_message));
  }

  /// @notice Returns message's body field as bytes29 (refer to TypedMemView library for details on bytes29 type)
  function body(bytes29 _message) internal pure returns (bytes29) {
    return _message.slice(PREFIX_LENGTH, _message.len() - PREFIX_LENGTH, 0);
  }

  function leaf(bytes29 _message) internal view returns (bytes32) {
    return
      messageHash(
        origin(_message),
        sender(_message),
        nonce(_message),
        destination(_message),
        recipient(_message),
        TypedMemView.clone(body(_message))
      );
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {MerkleLib} from "../libs/Merkle.sol";

/**
 * @title MerkleTreeManager
 * @author Illusory Systems Inc.
 * @notice Contains a Merkle tree instance and
 * exposes view functions for the tree.
 */
contract MerkleTreeManager {
  // ============ Libraries ============

  using MerkleLib for MerkleLib.Tree;
  MerkleLib.Tree public tree;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ============ Public Functions ============

  /**
   * @notice Calculates and returns tree's current root
   */
  function root() public view returns (bytes32) {
    return tree.root();
  }

  /**
   * @notice Returns the number of inserted leaves in the tree (current index)
   */
  function count() public view returns (uint256) {
    return tree.count;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {QueueLib} from "../libs/Queue.sol";
// ============ External Imports ============
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title QueueManager
 * @author Illusory Systems Inc.
 * @notice Contains a queue instance and
 * exposes view functions for the queue.
 **/
contract QueueManager is Initializable {
  // ============ Libraries ============

  using QueueLib for QueueLib.Queue;
  QueueLib.Queue internal queue;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ============ Initializer ============

  function __QueueManager_initialize() internal initializer {
    queue.initialize();
  }

  // ============ Public Functions ============

  /**
   * @notice Returns number of elements in queue
   */
  function queueLength() external view returns (uint256) {
    return queue.length();
  }

  /**
   * @notice Returns TRUE iff `_item` is in the queue
   */
  function queueContains(bytes32 _item) external view returns (bool) {
    return queue.contains(_item);
  }

  /**
   * @notice Returns last item enqueued to the queue
   */
  function queueEnd() external view returns (bytes32) {
    return queue.lastItem();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IUpdaterManager {
  function slashUpdater(address payable _reporter) external;

  function updater() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// import "@summa-tx/memview-sol/contracts/TypedMemView.sol";
import "./TypedMemView.sol";

library TypeCasts {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  function coerceBytes32(string memory _s) internal pure returns (bytes32 _b) {
    _b = bytes(_s).ref(0).index(0, uint8(bytes(_s).length));
  }

  // treat it as a null-terminated string of max 32 bytes
  function coerceString(bytes32 _buf) internal pure returns (string memory _newStr) {
    uint8 _slen = 0;
    while (_slen < 32 && _buf[_slen] != 0) {
      _slen++;
    }

    // solhint-disable-next-line no-inline-assembly
    assembly {
      _newStr := mload(0x40)
      mstore(0x40, add(_newStr, 0x40)) // may end up with extra
      mstore(_newStr, _slen)
      mstore(add(_newStr, 0x20), _buf)
    }
  }

  // alignment preserving cast
  function addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  // alignment preserving cast
  function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
    return address(uint160(uint256(_buf)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Version0} from "./Version0.sol";
import {NomadBase} from "./NomadBase.sol";
import {MerkleLib} from "../libs/Merkle.sol";
import {Message} from "../libs/Message.sol";
// ============ External Imports ============
// import {TypedMemView} from "@summa-tx/memview-sol/contracts/TypedMemView.sol";
import {TypedMemView} from "../libs/TypedMemView.sol";

/**
 * @title Replica
 * @author Illusory Systems Inc.
 * @notice Track root updates on Home,
 * prove and dispatch messages to end recipients.
 */
contract Replica is Version0, NomadBase {
  // ============ Libraries ============

  using MerkleLib for MerkleLib.Tree;
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using Message for bytes29;

  // ============ Enums ============

  // Status of Message:
  //   0 - None - message has not been proven or processed
  //   1 - Proven - message inclusion proof has been validated
  //   2 - Processed - message has been dispatched to recipient
  enum MessageStatus {
    None,
    Proven,
    Processed
  }

  // ============ Immutables ============

  // Minimum gas for message processing
  uint256 public immutable PROCESS_GAS;
  // Reserved gas (to ensure tx completes in case message processing runs out)
  uint256 public immutable RESERVE_GAS;

  // ============ Public Storage ============

  // Domain of home chain
  uint32 public remoteDomain;
  // Number of seconds to wait before root becomes confirmable
  uint256 public optimisticSeconds;
  // re-entrancy guard
  uint8 private entered;
  // Mapping of roots to allowable confirmation times
  mapping(bytes32 => uint256) public confirmAt;
  // Mapping of message leaves to MessageStatus
  mapping(bytes32 => MessageStatus) public messages;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[45] private __GAP;

  // ============ Events ============

  /**
   * @notice Emitted when message is processed
   * @param messageHash Hash of message that failed to process
   * @param success TRUE if the call was executed successfully, FALSE if the call reverted
   * @param returnData the return data from the external call
   */
  event Process(bytes32 indexed messageHash, bool indexed success, bytes indexed returnData);

  /**
   * @notice Emitted when the value for optimisticTimeout is set
   * @param timeout The new value for optimistic timeout
   */
  event SetOptimisticTimeout(uint256 timeout);

  /**
   * @notice Emitted when a root's confirmation is modified by governance
   * @param root The root for which confirmAt has been set
   * @param previousConfirmAt The previous value of confirmAt
   * @param newConfirmAt The new value of confirmAt
   */
  event SetConfirmation(bytes32 indexed root, uint256 previousConfirmAt, uint256 newConfirmAt);

  // ============ Constructor ============

  // solhint-disable-next-line no-empty-blocks
  constructor(
    uint32 _localDomain,
    uint256 _processGas,
    uint256 _reserveGas
  ) NomadBase(_localDomain) {
    require(_processGas >= 850_000, "!process gas");
    require(_reserveGas >= 15_000, "!reserve gas");
    PROCESS_GAS = _processGas;
    RESERVE_GAS = _reserveGas;
  }

  // ============ Initializer ============

  function initialize(
    uint32 _remoteDomain,
    address _updater,
    bytes32 _committedRoot,
    uint256 _optimisticSeconds
  ) public initializer {
    __NomadBase_initialize(_updater);
    // set storage variables
    entered = 1;
    remoteDomain = _remoteDomain;
    committedRoot = _committedRoot;
    confirmAt[_committedRoot] = 1;
    optimisticSeconds = _optimisticSeconds;
    emit SetOptimisticTimeout(_optimisticSeconds);
  }

  // ============ External Functions ============

  /**
   * @notice Called by external agent. Submits the signed update's new root,
   * marks root's allowable confirmation time, and emits an `Update` event.
   * @dev Reverts if update doesn't build off latest committedRoot
   * or if signature is invalid.
   * @param _oldRoot Old merkle root
   * @param _newRoot New merkle root
   * @param _signature Updater's signature on `_oldRoot` and `_newRoot`
   */
  function update(
    bytes32 _oldRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) external notFailed {
    // ensure that update is building off the last submitted root
    require(_oldRoot == committedRoot, "not current update");
    // validate updater signature
    require(_isUpdaterSignature(_oldRoot, _newRoot, _signature), "!updater sig");
    // Hook for future use
    _beforeUpdate();
    // set the new root's confirmation timer
    confirmAt[_newRoot] = block.timestamp + optimisticSeconds;
    // update committedRoot
    committedRoot = _newRoot;
    emit Update(remoteDomain, _oldRoot, _newRoot, _signature);
  }

  /**
   * @notice First attempts to prove the validity of provided formatted
   * `message`. If the message is successfully proven, then tries to process
   * message.
   * @dev Reverts if `prove` call returns false
   * @param _message Formatted message (refer to NomadBase.sol Message library)
   * @param _proof Merkle proof of inclusion for message's leaf
   * @param _index Index of leaf in home's merkle tree
   */
  function proveAndProcess(
    bytes memory _message,
    bytes32[32] calldata _proof,
    uint256 _index
  ) external {
    require(prove(keccak256(_message), _proof, _index), "!prove");
    process(_message);
  }

  /**
   * @notice Given formatted message, attempts to dispatch
   * message payload to end recipient.
   * @dev Recipient must implement a `handle` method (refer to IMessageRecipient.sol)
   * Reverts if formatted message's destination domain is not the Replica's domain,
   * if message has not been proven,
   * or if not enough gas is provided for the dispatch transaction.
   * @param _message Formatted message
   * @return _success TRUE iff dispatch transaction succeeded
   */
  function process(bytes memory _message) public returns (bool _success) {
    bytes29 _m = _message.ref(0);
    // ensure message was meant for this domain
    require(_m.destination() == localDomain, "!destination");
    // ensure message has been proven
    bytes32 _messageHash = _m.keccak();
    require(messages[_messageHash] == MessageStatus.Proven, "!proven");
    // check re-entrancy guard
    require(entered == 1, "!reentrant");
    entered = 0;
    // update message status as processed
    messages[_messageHash] = MessageStatus.Processed;
    // A call running out of gas TYPICALLY errors the whole tx. We want to
    // a) ensure the call has a sufficient amount of gas to make a
    //    meaningful state change.
    // b) ensure that if the subcall runs out of gas, that the tx as a whole
    //    does not revert (i.e. we still mark the message processed)
    // To do this, we require that we have enough gas to process
    // and still return. We then delegate only the minimum processing gas.
    require(gasleft() >= PROCESS_GAS + RESERVE_GAS, "!gas");
    // get the message recipient
    address _recipient = _m.recipientAddress();
    // set up for assembly call
    uint256 _toCopy;
    uint256 _maxCopy = 256;
    uint256 _gas = PROCESS_GAS;
    // allocate memory for returndata
    bytes memory _returnData = new bytes(_maxCopy);
    bytes memory _calldata = abi.encodeWithSignature(
      "handle(uint32,uint32,bytes32,bytes)",
      _m.origin(),
      _m.nonce(),
      _m.sender(),
      _m.body().clone()
    );
    // dispatch message to recipient
    // by assembly calling "handle" function
    // we call via assembly to avoid memcopying a very large returndata
    // returned by a malicious contract
    assembly {
      _success := call(
        _gas, // gas
        _recipient, // recipient
        0, // ether value
        add(_calldata, 0x20), // inloc
        mload(_calldata), // inlen
        0, // outloc
        0 // outlen
      )
      // limit our copy to 256 bytes
      _toCopy := returndatasize()
      if gt(_toCopy, _maxCopy) {
        _toCopy := _maxCopy
      }
      // Store the length of the copied bytes
      mstore(_returnData, _toCopy)
      // copy the bytes from returndata[0:_toCopy]
      returndatacopy(add(_returnData, 0x20), 0, _toCopy)
    }
    // emit process results
    emit Process(_messageHash, _success, _returnData);
    // reset re-entrancy guard
    entered = 1;
  }

  // ============ External Owner Functions ============

  /**
   * @notice Set optimistic timeout period for new roots
   * @dev Only callable by owner (Governance)
   * @param _optimisticSeconds New optimistic timeout period
   */
  function setOptimisticTimeout(uint256 _optimisticSeconds) external onlyOwner {
    optimisticSeconds = _optimisticSeconds;
    emit SetOptimisticTimeout(_optimisticSeconds);
  }

  /**
   * @notice Set Updater role
   * @dev MUST ensure that all roots signed by previous Updater have
   * been relayed before calling. Only callable by owner (Governance)
   * @param _updater New Updater
   */
  function setUpdater(address _updater) external onlyOwner {
    _setUpdater(_updater);
  }

  /**
   * @notice Set confirmAt for a given root
   * @dev To be used if in the case that fraud is proven
   * and roots need to be deleted / added. Only callable by owner (Governance)
   * @param _root The root for which to modify confirm time
   * @param _confirmAt The new confirmation time. Set to 0 to "delete" a root.
   */
  function setConfirmation(bytes32 _root, uint256 _confirmAt) external onlyOwner {
    uint256 _previousConfirmAt = confirmAt[_root];
    confirmAt[_root] = _confirmAt;
    emit SetConfirmation(_root, _previousConfirmAt, _confirmAt);
  }

  // ============ Public Functions ============

  /**
   * @notice Check that the root has been submitted
   * and that the optimistic timeout period has expired,
   * meaning the root can be processed
   * @param _root the Merkle root, submitted in an update, to check
   * @return TRUE iff root has been submitted & timeout has expired
   */
  function acceptableRoot(bytes32 _root) public view returns (bool) {
    uint256 _time = confirmAt[_root];
    if (_time == 0) {
      return false;
    }
    return block.timestamp >= _time;
  }

  /**
   * @notice Attempts to prove the validity of message given its leaf, the
   * merkle proof of inclusion for the leaf, and the index of the leaf.
   * @dev Reverts if message's MessageStatus != None (i.e. if message was
   * already proven or processed)
   * @dev For convenience, we allow proving against any previous root.
   * This means that witnesses never need to be updated for the new root
   * @param _leaf Leaf of message to prove
   * @param _proof Merkle proof of inclusion for leaf
   * @param _index Index of leaf in home's merkle tree
   * @return Returns true if proof was valid and `prove` call succeeded
   **/
  function prove(
    bytes32 _leaf,
    bytes32[32] calldata _proof,
    uint256 _index
  ) public returns (bool) {
    // ensure that message has not been proven or processed
    require(messages[_leaf] == MessageStatus.None, "!MessageStatus.None");
    // calculate the expected root based on the proof
    bytes32 _calculatedRoot = MerkleLib.branchRoot(_leaf, _proof, _index);
    // if the root is valid, change status to Proven
    if (acceptableRoot(_calculatedRoot)) {
      messages[_leaf] = MessageStatus.Proven;
      return true;
    }
    return false;
  }

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   */
  function homeDomainHash() public view override returns (bytes32) {
    return _homeDomainHash(remoteDomain);
  }

  // ============ Internal Functions ============

  /**
   * @notice Moves the contract into failed state
   * @dev Called when a Double Update is submitted
   */
  function _fail() internal override {
    _setFailed();
  }

  /// @notice Hook for potential future use
  // solhint-disable-next-line no-empty-blocks
  function _beforeUpdate() internal {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../ProposedOwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TestProposedOwnable is Initializable, ProposedOwnableUpgradeable {
  uint256 private value;

  function initialize(uint256 _newValue) public initializer {
    __ProposedOwnable_init();

    value = _newValue;
  }

  function setValue(uint256 _newValue) public {
    value = _newValue;
  }

  function getValue() public view returns (uint256) {
    return value;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.11;

// ============ Internal Imports ============
import {IConnextHandler} from "../../../interfaces/IConnextHandler.sol";
import {Router} from "../Router.sol";
import {XAppConnectionClient} from "../XAppConnectionClient.sol";
import {PromiseMessage} from "./PromiseMessage.sol";
import {IBridgeToken} from "../../interfaces/bridge/IBridgeToken.sol";

// ============ External Imports ============
import {Home} from "../../../nomad-core/contracts/Home.sol";
import {Version0} from "../../../nomad-core/contracts/Version0.sol";
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

/**
 * @title PromiseRouter
 */
contract PromiseRouter is Version0, Router {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using PromiseMessage for bytes29;

  // ========== Custom Errors ===========

  error PromiseRouter__onlyConnext_notConnext();
  error PromiseRouter__send_calldataEmpty();
  error PromiseRouter__send_callbackAddressEmpty();

  // ============ Public Storage ============

  IConnextHandler public connext;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ======== Events =========

  /**
   * @notice Emitted when a fees claim has been initialized in this domain
   * @param domain The domain where to claim the fees
   * @param remote Remote PromiseRouter address
   * @param transferId The transferId
   * @param callbackAddress The address of the callback
   * @param data The calldata which will executed on the destination domain
   * @param message The message sent to the destination domain
   */
  event Send(uint32 domain, bytes32 remote, bytes32 transferId, address callbackAddress, bytes data, bytes message);

  /**
   * @notice Emitted when the a fees claim message has arrived to this domain
   * @param originAndNonce Domain where the transfer originated and the unique identifier
   * for the message from origin to destination, combined in a single field ((origin << 32) & nonce)
   * @param origin Domain where the transfer originated
   * @param transferId The transferId
   * @param callbackAddress The address of the callback
   * @param data The calldata
   */
  event Receive(
    uint64 indexed originAndNonce,
    uint32 indexed origin,
    bytes32 transferId,
    address callbackAddress,
    bytes data
  );

  /**
   * @notice Emitted when a new Connext address is set
   * @param connext The new connext address
   */
  event SetConnext(address indexed connext);

  // ======== Receive =======
  receive() external payable {}

  fallback() external payable {}

  // ============ Modifiers ============

  /**
   * @notice Restricts the caller to the local bridge router
   */
  modifier onlyConnext() {
    if (msg.sender != address(connext)) revert PromiseRouter__onlyConnext_notConnext();
    _;
  }

  // ======== Initializer ========

  function initialize(address _xAppConnectionManager) public initializer {
    __XAppConnectionClient_initialize(_xAppConnectionManager);
  }

  /**
   * @notice Sets the Connext.
   * @dev Connext and relayer fee router store references to each other
   * @param _connext The address of the Connext implementation
   */
  function setConnext(address _connext) external onlyOwner {
    connext = IConnextHandler(_connext);
    emit SetConnext(_connext);
  }

  // ======== External: Send PromiseCallback =========

  /**
   * @notice Sends a request to claim the fees in the originated domain
   * @param _domain The domain where to claim the fees
   * @param _transferId The transferId
   * @param _callbackAddress A callback address to be called when promise callback is received
   * @param _calldata The calldata for promise callback
   */
  function send(
    uint32 _domain,
    bytes32 _transferId,
    address _callbackAddress,
    bytes calldata _calldata
  ) external onlyConnext {
    if (_calldata.length == 0) revert PromiseRouter__send_calldataEmpty();
    if (_callbackAddress == address(0)) revert PromiseRouter__send_callbackAddressEmpty();

    // get remote PromiseRouter address; revert if not found
    bytes32 remote = _mustHaveRemote(_domain);

    bytes memory message = PromiseMessage.formatPromiseCallback(_transferId, _callbackAddress, _calldata);

    xAppConnectionManager.home().dispatch(_domain, remote, message);

    // emit Send event
    emit Send(_domain, remote, _transferId, _callbackAddress, _calldata, message);
  }

  // ======== External: Handle =========

  /**
   * @notice Handles an incoming message
   * @param _origin The origin domain
   * @param _nonce The unique identifier for the message from origin to destination
   * @param _sender The sender address
   * @param _message The message
   */
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external override onlyReplica onlyRemoteRouter(_origin, _sender) {
    // parse transferId, callbackAddress, callData from message
    bytes29 _msg = _message.ref(0).mustBePromiseCallback();

    bytes32 transferId = _msg.transferId();
    address callbackAddress = _msg.callbackAddress();
    bytes memory data = _msg.returnCallData();

    //TODO process callback

    // emit Receive event
    emit Receive(_originAndNonce(_origin, _nonce), _origin, transferId, callbackAddress, data);
  }

  function process(bytes32 transactionId, bytes memory _message) internal {
    // Should parse out the return data and callback address from message
    // Should execute the callback() function on the provided Callback address
    // Should enforce relayer is whitelisted by calling local connext contract
    // Should transfer the stored relayer fee to the msg.sender
  }

  /**
   * @dev explicit override for compiler inheritance
   * @dev explicit override for compiler inheritance
   * @return domain of chain on which the contract is deployed
   */
  function _localDomain() internal view override(XAppConnectionClient) returns (uint32) {
    return XAppConnectionClient._localDomain();
  }

  /**
   * @notice Internal utility function that combines
   * `_origin` and `_nonce`.
   * @dev Both origin and nonce should be less than 2^32 - 1
   * @param _origin Domain of chain where the transfer originated
   * @param _nonce The unique identifier for the message from origin to destination
   * @return Returns (`_origin` << 32) & `_nonce`
   */
  function _originAndNonce(uint32 _origin, uint32 _nonce) internal pure returns (uint64) {
    return (uint64(_origin) << 32) | _nonce;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "../nomad-xapps/contracts/connext/ConnextMessage.sol";

interface IConnextHandler {
  // ============= Structs =============

  /**
   * @notice These are the call parameters that will remain constant between the
   * two chains. They are supplied on `xcall` and should be asserted on `execute`
   * @property to - The account that receives funds, in the event of a crosschain call,
   * will receive funds if the call fails.
   * @param to - The address you are sending funds (and potentially data) to
   * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
   * @param originDomain - The originating domain (i.e. where `xcall` is called). Must match nomad domain schema
   * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called). Must match nomad domain schema
   */
  struct CallParams {
    address to;
    bytes callData;
    uint32 originDomain;
    uint32 destinationDomain;
  }

  /**
   * @notice The arguments you supply to the `xcall` function called by user on origin domain
   * @param params - The CallParams. These are consistent across sending and receiving chains
   * @param transactingAssetId - The asset the caller sent with the transfer. Can be the adopted, canonical,
   * or the representational asset
   * @param amount - The amount of transferring asset the tx called xcall with
   * @param relayerFee - The amount of relayer fee the tx called xcall with
   */
  struct XCallArgs {
    CallParams params;
    address transactingAssetId; // Could be adopted, local, or wrapped
    uint256 amount;
    uint256 relayerFee;
  }

  /**
   * @notice
   * @param params - The CallParams. These are consistent across sending and receiving chains
   * @param local - The local asset for the transfer, will be swapped to the adopted asset if
   * appropriate
   * @param routers - The routers who you are sending the funds on behalf of
   * @param amount - The amount of liquidity the router provided or the bridge forwarded, depending on
   * if fast liquidity was used
   * @param nonce - The nonce used to generate transfer id
   * @param originSender - The msg.sender of the xcall on origin domain
   */
  struct ExecuteArgs {
    CallParams params;
    address local; // local representation of canonical token
    address[] routers;
    bytes[] routerSignatures;
    uint256 amount;
    uint256 nonce;
    address originSender;
  }

  // ============ Admin Functions ============

  function initialize(
    uint256 _domain,
    address _xAppConnectionManager,
    address _tokenRegistry, // Nomad token registry
    address _wrappedNative,
    address _relayerFeeRouter
  ) external;

  function setupRouter(
    address router,
    address owner,
    address recipient
  ) external;

  function removeRouter(address router) external;

  function addStableSwapPool(ConnextMessage.TokenId calldata canonical, address stableSwapPool) external;

  function setupAsset(
    ConnextMessage.TokenId calldata canonical,
    address adoptedAssetId,
    address stableSwapPool
  ) external;

  function removeAssetId(bytes32 canonicalId, address adoptedAssetId) external;

  function setMaxRoutersPerTransfer(uint256 newMaxRouters) external;

  function addRelayer(address relayer) external;

  function removeRelayer(address relayer) external;

  // ============ Public Functions ===========

  function addLiquidityFor(
    uint256 amount,
    address local,
    address router
  ) external payable;

  function addLiquidity(uint256 amount, address local) external payable;

  function removeLiquidity(
    uint256 amount,
    address local,
    address payable to
  ) external;

  function xcall(XCallArgs calldata _args) external payable returns (bytes32);

  function execute(ExecuteArgs calldata _args) external returns (bytes32);

  function initiateClaim(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds
  ) external;

  function claim(address _recipient, bytes32[] calldata _transferIds) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {XAppConnectionClient} from "./XAppConnectionClient.sol";
// ============ External Imports ============
import {IMessageRecipient} from "../../nomad-core/interfaces/IMessageRecipient.sol";

abstract contract Router is XAppConnectionClient, IMessageRecipient {
  // ============ Mutable Storage ============

  mapping(uint32 => bytes32) public remotes;
  uint256[49] private __GAP; // gap for upgrade safety

  // ============ Modifiers ============

  /**
   * @notice Only accept messages from a remote Router contract
   * @param _origin The domain the message is coming from
   * @param _router The address the message is coming from
   */
  modifier onlyRemoteRouter(uint32 _origin, bytes32 _router) {
    require(_isRemoteRouter(_origin, _router), "!remote router");
    _;
  }

  // ============ External functions ============

  /**
   * @notice Register the address of a Router contract for the same xApp on a remote chain
   * @param _domain The domain of the remote xApp Router
   * @param _router The address of the remote xApp Router
   */
  function enrollRemoteRouter(uint32 _domain, bytes32 _router) external onlyOwner {
    remotes[_domain] = _router;
  }

  // ============ Virtual functions ============

  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external virtual override;

  // ============ Internal functions ============
  /**
   * @notice Return true if the given domain / router is the address of a remote xApp Router
   * @param _domain The domain of the potential remote xApp Router
   * @param _router The address of the potential remote xApp Router
   */
  function _isRemoteRouter(uint32 _domain, bytes32 _router) internal view returns (bool) {
    return remotes[_domain] == _router;
  }

  /**
   * @notice Assert that the given domain has a xApp Router registered and return its address
   * @param _domain The domain of the chain for which to get the xApp Router
   * @return _remote The address of the remote xApp Router on _domain
   */
  function _mustHaveRemote(uint32 _domain) internal view returns (bytes32 _remote) {
    _remote = remotes[_domain];
    require(_remote != bytes32(0), "!remote");
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.11;

// ============ External Imports ============
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

library PromiseMessage {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Enums ============

  // WARNING: do NOT re-write the numbers / order
  // of message types in an upgrade;
  // will cause in-flight messages to be mis-interpreted
  enum Types {
    Invalid, // 0
    PromiseCallback // 1
  }

  // ============ Constants ============
  uint256 private constant IDENTIFIER_LEN = 1;
  // 1 byte identifier + 32 bytes transferId + 20 bytes callback + 32 bytes length + x bytes data
  // before: 1 byte identifier + 32 bytes transferId + 20 bytes callback = 53 bytes
  uint256 private constant LENGTH_CALLDATA_START = 53;
  uint8 private constant LENGTH_CALLDATA_LEN = 32;

  // before: 1 byte identifier + 32 bytes transferId + 20 bytes callback + 32 bytes length = 85 bytes
  uint256 private constant CALLDATA_START = 85;

  // ============ Modifiers ============

  /**
   * @notice Asserts a message is of type `_t`
   * @param _view The message
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Formatters ============

  /**
   * @notice Formats an promise callback message
   * @param _transferId The address of the relayer
   * @param _callbackAddress The callback address on destination domain
   * @param _data The callback data
   * @return The formatted message
   */
  function formatPromiseCallback(
    bytes32 _transferId,
    address _callbackAddress,
    bytes calldata _data
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(Types.PromiseCallback), _transferId, _callbackAddress, _data.length, _data);
  }

  // ============ Getters ============

  /**
   * @notice Parse the transferId from the message
   * @param _view The message
   * @return The transferId
   */
  function transferId(bytes29 _view) internal pure typeAssert(_view, Types.PromiseCallback) returns (bytes32) {
    // before = 1 byte identifier
    return _view.index(1, 32);
  }

  /**
   * @notice Parse the callback address from the message
   * @param _view The message
   * @return The callback address
   */
  function callbackAddress(bytes29 _view) internal pure typeAssert(_view, Types.PromiseCallback) returns (address) {
    // before = 1 byte identifier + 32 bytes transferId
    return _view.indexAddress(33);
  }

  /**
   * @notice Parse the calldata length from the message
   * @param _view The message
   * @return The calldata length
   */
  function lengthOfCalldata(bytes29 _view) internal pure typeAssert(_view, Types.PromiseCallback) returns (uint256) {
    return _view.indexUint(LENGTH_CALLDATA_START, LENGTH_CALLDATA_LEN);
  }

  /**
   * @notice Parse calldata from the message
   * @param _view The message
   * @return returnData
   */
  function returnCallData(bytes29 _view)
    internal
    view
    typeAssert(_view, Types.PromiseCallback)
    returns (bytes memory returnData)
  {
    uint256 length = lengthOfCalldata(_view);

    uint8 bitLength = uint8(length * 8);
    uint256 _loc = _view.loc();

    uint256 _mask;
    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      _mask := sar(sub(bitLength, 1), 0x8000000000000000000000000000000000000000000000000000000000000000)
      returnData := and(mload(add(_loc, CALLDATA_START)), _mask)
    }
  }

  /**
   * @notice Checks that view is a valid message length
   * @param _view The bytes string
   * @return TRUE if message is valid
   */
  function isValidPromiseCallbackLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    uint256 _length = lengthOfCalldata(_view);
    // before = 1 byte identifier + 32 bytes transferId + 20 bytes callback address + 32 bytes length + x bytes data
    // nonzero callback data
    return _len > CALLDATA_START && _length > 0 && (CALLDATA_START + _length) == _len;
  }

  /**
   * @notice Converts to a Promise callback message
   * @param _view The message
   * @return The newly typed message
   */
  function tryAsPromiseCallback(bytes29 _view) internal pure returns (bytes29) {
    if (isValidPromiseCallbackLength(_view)) {
      return _view.castTo(uint40(Types.PromiseCallback));
    }
    return TypedMemView.nullView();
  }

  /**
   * @notice Asserts that the message is of type PromiseCallback
   * @param _view The message
   * @return The message
   */
  function mustBePromiseCallback(bytes29 _view) internal pure returns (bytes29) {
    return tryAsPromiseCallback(_view).assertValid();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

// ============ Imports ============
// TODO: import from nomad, summa packages
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";
import {Home} from "../../../nomad-core/contracts/Home.sol";
import {RelayerFeeRouter} from "../../../nomad-xapps/contracts/relayer-fee-router/RelayerFeeRouter.sol";
import {Router} from "../Router.sol";

import {ConnextMessage} from "./ConnextMessage.sol";

import {ConnextLogic} from "../../../lib/Connext/ConnextLogic.sol";

import {ITokenRegistry} from "../../interfaces/bridge/ITokenRegistry.sol";
import {IWrapped} from "../../../interfaces/IWrapped.sol";
import {IConnextHandler} from "../../../interfaces/IConnextHandler.sol";
import {IExecutor} from "../../../interfaces/IExecutor.sol";
import {IStableSwap} from "../../../interfaces/IStableSwap.sol";

import {Executor} from "../../../interpreters/Executor.sol";
import {RouterPermissionsManager} from "../../../RouterPermissionsManager.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title ConnextHandler
 * @author Connext Labs
 * @notice Contains logic to facilitate bridging via nomad, including the provision of
 * fast liquidity
 * @dev This contract primarily contains the storage used by the functions within the
 * `ConnextLogic` contract, which contains the meaningful logic
 */
contract ConnextHandler is
  Initializable,
  ReentrancyGuardUpgradeable,
  Router,
  RouterPermissionsManager,
  IConnextHandler
{
  // ============ Libraries ============

  using SafeERC20Upgradeable for IERC20Upgradeable;

  // ============ Constants ============

  // TODO: enable setting these constants via admin fn
  uint256 public LIQUIDITY_FEE_NUMERATOR;
  uint256 public LIQUIDITY_FEE_DENOMINATOR;

  /**
   * @notice Contains hash of empty bytes
   */
  bytes32 internal EMPTY;

  // ============ Private storage ============
  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;

  // ============ Public storage ============

  /**
   * @notice The local nomad relayer fee router
   */
  RelayerFeeRouter public relayerFeeRouter;

  /**
   * @notice The address of the wrapper for the native asset on this domain
   * @dev Needed because the nomad only handles ERC20 assets
   */
  IWrapped public wrapper;

  /**
   * @notice Nonce for the contract, used to keep unique transfer ids.
   * @dev Assigned at first interaction (xcall on origin domain);
   */
  uint256 public nonce;

  /**
   * @notice The external contract that will execute crosschain calldata
   */
  IExecutor public executor;

  /**
   * @notice The domain this contract exists on
   * @dev Must match the nomad domain, which is distinct from the "chainId"
   */
  uint256 public domain;

  /**
   * @notice The local nomad token registry
   */
  ITokenRegistry public tokenRegistry;

  /**
   * @notice Mapping holding the AMMs for swapping in and out of local assets
   * @dev Swaps for an adopted asset <> nomad local asset (i.e. POS USDC <> madUSDC on polygon)
   */
  mapping(bytes32 => IStableSwap) public adoptedToLocalPools;

  /**
   * @notice Mapping of whitelisted assets on same domain as contract
   * @dev Mapping is keyed on the canonical token identifier matching what is stored in the token
   * registry
   */
  mapping(bytes32 => bool) public approvedAssets;

  /**
   * @notice Mapping of canonical to adopted assets on this domain
   * @dev If the adopted asset is the native asset, the keyed address will
   * be the wrapped asset address
   */
  mapping(address => ConnextMessage.TokenId) public adoptedToCanonical;

  /**
   * @notice Mapping of adopted to canonical on this domain
   * @dev If the adopted asset is the native asset, the stored address will be the
   * wrapped asset address
   */
  mapping(bytes32 => address) public canonicalToAdopted;

  /**
   * @notice Mapping to determine if transfer is reconciled
   */
  mapping(bytes32 => bool) public reconciledTransfers;

  /**
   * @notice Mapping holding router address that provided fast liquidity
   */
  mapping(bytes32 => address[]) public routedTransfers;

  /**
   * @notice Mapping of router to available balance of an asset
   * @dev Routers should always store liquidity that they can expect to receive via the bridge on
   * this domain (the nomad local asset)
   */
  mapping(address => mapping(address => uint256)) public routerBalances;

  /**
   * @notice Mapping of approved relayers
   * @dev Send relayer fee if msg.sender is approvedRelayer. otherwise revert()
   */
  mapping(address => bool) public approvedRelayers;

  /**
   * @notice Stores the relayer fee for a transfer. Updated on origin domain when a user calls xcall or bump
   * @dev This will track all of the relayer fees assigned to a transfer by id, including any bumps made by the relayer
   */
  mapping(bytes32 => uint256) public relayerFees;

  /**
   * @notice Stores the relayer of a transfer. Updated on the destination domain when a relayer calls execute
   * for transfer
   * @dev When relayer claims, must check that the msg.sender has forwarded transfer
   */
  mapping(bytes32 => address) public transferRelayer;

  /**
   * @notice The max amount of routers a payment can be routed through
   */
  uint256 public maxRoutersPerTransfer;

  // ============ Errors ============

  error ConnextHandler__addLiquidityForRouter_routerEmpty();
  error ConnextHandler__addLiquidityForRouter_amountIsZero();
  error ConnextHandler__addLiquidityForRouter_badRouter();
  error ConnextHandler__addLiquidityForRouter_badAsset();
  error ConnextHandler__setMaxRoutersPerTransfer_invalidMaxRoutersPerTransfer();
  error ConnextHandler__onlyRelayerFeeRouter_notRelayerFeeRouter();
  error ConnextHandler__bumpTransfer_valueIsZero();
  error ConnextHandler__execute_unapprovedRelayer();

  // ============ Modifiers ============

  /**
   * @notice Restricts the caller to the local relayer fee router
   */
  modifier onlyRelayerFeeRouter() {
    if (msg.sender != address(relayerFeeRouter)) revert ConnextHandler__onlyRelayerFeeRouter_notRelayerFeeRouter();
    _;
  }

  // ========== Initializer ============

  function initialize(
    uint256 _domain,
    address _xAppConnectionManager,
    address _tokenRegistry, // Nomad token registry
    address _wrappedNative,
    address _relayerFeeRouter
  ) public override initializer {
    __XAppConnectionClient_initialize(_xAppConnectionManager);
    __ReentrancyGuard_init();
    __RouterPermissionsManager_init();

    nonce = 0;
    domain = _domain;
    relayerFeeRouter = RelayerFeeRouter(_relayerFeeRouter);
    executor = new Executor(address(this));
    tokenRegistry = ITokenRegistry(_tokenRegistry);
    wrapper = IWrapped(_wrappedNative);
    EMPTY = hex"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
    LIQUIDITY_FEE_NUMERATOR = 9995;
    LIQUIDITY_FEE_DENOMINATOR = 10000;
    maxRoutersPerTransfer = 5;
  }

  // ============ Owner Functions ============

  /**
   * @notice Used to set router initial properties
   * @param _router Router address to setup
   * @param _owner Initial Owner of router
   * @param _recipient Initial Recipient of router
   */
  function setupRouter(
    address _router,
    address _owner,
    address _recipient
  ) external onlyOwner {
    _setupRouter(_router, _owner, _recipient);
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param _router Router address to remove
   */
  function removeRouter(address _router) external override onlyOwner {
    _removeRouter(_router);
  }

  /**
   * @notice Adds a stable swap pool for the local <> adopted asset.
   */
  function addStableSwapPool(ConnextMessage.TokenId calldata _canonical, address _stableSwapPool)
    external
    override
    onlyOwner
  {
    ConnextLogic.addStableSwapPool(_canonical, _stableSwapPool, adoptedToLocalPools);
  }

  /**
   * @notice Used to add supported assets. This is an admin only function
   * @dev When whitelisting the canonical asset, all representational assets would be
   * whitelisted as well. In the event you have a different adopted asset (i.e. PoS USDC
   * on polygon), you should *not* whitelist the adopted asset. The stable swap pool
   * address used should allow you to swap between the local <> adopted asset
   * @param _canonical - The canonical asset to add by id and domain. All representations
   * will be whitelisted as well
   * @param _adoptedAssetId - The used asset id for this domain (i.e. PoS USDC for
   * polygon)
   */
  function setupAsset(
    ConnextMessage.TokenId calldata _canonical,
    address _adoptedAssetId,
    address _stableSwapPool
  ) external override onlyOwner {
    // Add the asset
    ConnextLogic.addAssetId(
      _canonical,
      _adoptedAssetId,
      address(wrapper),
      approvedAssets,
      adoptedToCanonical,
      canonicalToAdopted
    );

    // Add the swap pool
    ConnextLogic.addStableSwapPool(_canonical, _stableSwapPool, adoptedToLocalPools);
  }

  /**
   * @notice Used to remove assets from the whitelist
   * @param _canonicalId - Token id to remove
   * @param _adoptedAssetId - Corresponding adopted asset to remove
   */
  function removeAssetId(bytes32 _canonicalId, address _adoptedAssetId) external override onlyOwner {
    ConnextLogic.removeAssetId(
      _canonicalId,
      _adoptedAssetId,
      address(wrapper),
      approvedAssets,
      adoptedToLocalPools,
      adoptedToCanonical
    );
  }

  /**
   * @notice Used to add approved relayer
   * @param _relayer - The relayer address to add
   */
  function addRelayer(address _relayer) external override onlyOwner {
    ConnextLogic.addRelayer(_relayer, approvedRelayers);
  }

  /**
   * @notice Used to remove approved relayer
   * @param _relayer - The relayer address to remove
   */
  function removeRelayer(address _relayer) external override onlyOwner {
    ConnextLogic.removeRelayer(_relayer, approvedRelayers);
  }

  /**
   * @notice Used to set the max amount of routers a payment can be routed through
   * @param _newMaxRouters The new max amount of routers
   */
  function setMaxRoutersPerTransfer(uint256 _newMaxRouters) external override onlyOwner {
    ConnextLogic.setMaxRoutersPerTransfer(_newMaxRouters, maxRoutersPerTransfer);

    maxRoutersPerTransfer = _newMaxRouters;
  }

  // ============ External functions ============

  receive() external payable {}

  /**
   * @notice This is used by anyone to increase a router's available liquidity for a given asset.
   * @dev The liquidity will be held in the local asset, which is the representation if you
   * are *not* on the canonical domain, and the canonical asset otherwise.
   * @param _amount - The amount of liquidity to add for the router
   * @param _local - The address of the asset you're adding liquidity for. If adding liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   * @param _router The router you are adding liquidity on behalf of
   */
  function addLiquidityFor(
    uint256 _amount,
    address _local,
    address _router
  ) external payable override nonReentrant {
    _addLiquidityForRouter(_amount, _local, _router);
  }

  /**
   * @notice This is used by any router to increase their available liquidity for a given asset.
   * @dev The liquidity will be held in the local asset, which is the representation if you
   * are *not* on the canonical domain, and the canonical asset otherwise.
   * @param _amount - The amount of liquidity to add for the router
   * @param _local - The address of the asset you're adding liquidity for. If adding liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   */
  function addLiquidity(uint256 _amount, address _local) external payable override nonReentrant {
    _addLiquidityForRouter(_amount, _local, msg.sender);
  }

  /**
   * @notice This is used by any router to decrease their available liquidity for a given asset.
   * @param _amount - The amount of liquidity to remove for the router
   * @param _local - The address of the asset you're removing liquidity from. If removing liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   * @param _to The address that will receive the liquidity being removed
   */
  function removeLiquidity(
    uint256 _amount,
    address _local,
    address payable _to
  ) external override nonReentrant {
    // transfer to specicfied recipient IF recipient not set
    address recipient = getRouterRecipient(msg.sender);
    recipient = recipient == address(0) ? _to : recipient;

    ConnextLogic.removeLiquidity(_amount, _local, recipient, routerBalances, wrapper);
  }

  /**
   * @notice This function is called by a user who is looking to bridge funds
   * @dev This contract must have approval to transfer the adopted assets. They are then swapped to
   * the local nomad assets via the configured AMM and sent over the bridge router.
   * @param _args - The XCallArgs
   * @return The transfer id of the crosschain transfer
   */
  function xcall(XCallArgs calldata _args) external payable override returns (bytes32) {
    // get remote BridgeRouter address; revert if not found
    bytes32 remote = _mustHaveRemote(_args.params.destinationDomain);

    ConnextLogic.XCallLibArgs memory libArgs = ConnextLogic.XCallLibArgs({
      xCallArgs: _args,
      wrapper: wrapper,
      nonce: nonce,
      tokenRegistry: tokenRegistry,
      domain: domain,
      home: xAppConnectionManager.home(),
      remote: remote
    });

    (bytes32 transferId, uint256 newNonce) = ConnextLogic.xcall(
      libArgs,
      adoptedToCanonical,
      adoptedToLocalPools,
      relayerFees
    );

    nonce = newNonce;

    return transferId;
  }

  /**
   * @notice Handles an incoming message
   * @dev This function relies on nomad relayers and should not consume arbitrary amounts of
   * gas
   * @param _origin The origin domain
   * @param _nonce The unique identifier for the message from origin to destination
   * @param _sender The sender address
   * @param _message The message
   */
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external override onlyReplica onlyRemoteRouter(_origin, _sender) {
    // handle the action
    ConnextLogic.reconcile(_origin, _message, reconciledTransfers, tokenRegistry, routedTransfers, routerBalances);
  }

  /**
   * @notice Called on the destination domain to disburse correct assets to end recipient
   * and execute any included calldata
   * @dev Can be called prior to or after `handle`, depending if fast liquidity is being
   * used.
   */
  function execute(ExecuteArgs calldata _args) external override returns (bytes32 transferId) {
    // If the sender is not approved relayer, revert()
    if (!approvedRelayers[msg.sender]) {
      revert ConnextHandler__execute_unapprovedRelayer();
    }

    ConnextLogic.ExecuteLibArgs memory libArgs = ConnextLogic.ExecuteLibArgs({
      executeArgs: _args,
      isRouterOwnershipRenounced: isRouterOwnershipRenounced(),
      maxRoutersPerTransfer: maxRoutersPerTransfer,
      tokenRegistry: tokenRegistry,
      wrapper: wrapper,
      executor: executor,
      liquidityFeeNumerator: LIQUIDITY_FEE_NUMERATOR,
      liquidityFeeDenominator: LIQUIDITY_FEE_DENOMINATOR
    });

    return
      ConnextLogic.execute(
        libArgs,
        routedTransfers,
        reconciledTransfers,
        routerBalances,
        adoptedToLocalPools,
        canonicalToAdopted,
        routerInfo,
        transferRelayer
      );
  }

  /**
   * @notice Anyone can call this function on the origin domain to increase the relayer fee for a transfer.
   * @param _transferId - The unique identifier of the crosschain transaction
   */
  function bumpTransfer(bytes32 _transferId) external payable {
    ConnextLogic.bumpTransfer(_transferId, relayerFees);
  }

  /**
   * @notice Called by relayer when they want to claim owed funds on a given domain
   * @dev Domain should be the origin domain of all the transfer ids
   * @param _recipient - address on origin chain to send claimed funds to
   * @param _domain - domain to claim funds on
   * @param _transferIds - transferIds to claim
   */
  function initiateClaim(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds
  ) external override {
    ConnextLogic.initiateClaim(_domain, _recipient, _transferIds, relayerFeeRouter, transferRelayer);
  }

  /**
   * @notice Pays out a relayer for the given fees
   * @dev Called by the RelayerFeeRouter.handle message. The validity of the transferIds is
   * asserted before dispatching the message.
   * @param _recipient - address on origin chain to send claimed funds to
   * @param _transferIds - transferIds to claim
   */
  function claim(address _recipient, bytes32[] calldata _transferIds) external override onlyRelayerFeeRouter {
    ConnextLogic.claim(_recipient, _transferIds, relayerFees);
  }

  // ============ Internal functions ============

  /**
   * @notice Contains the logic to verify + increment a given routers liquidity
   * @dev The liquidity will be held in the local asset, which is the representation if you
   * are *not* on the canonical domain, and the canonical asset otherwise.
   * @param _amount - The amount of liquidity to add for the router
   * @param _local - The address of the nomad representation of the asset
   * @param _router - The router you are adding liquidity on behalf of
   */
  function _addLiquidityForRouter(
    uint256 _amount,
    address _local,
    address _router
  ) internal {
    // Sanity check: router is sensible
    if (_router == address(0)) revert ConnextHandler__addLiquidityForRouter_routerEmpty();

    // Sanity check: nonzero amounts
    if (_amount == 0) revert ConnextHandler__addLiquidityForRouter_amountIsZero();

    // Get the canonical asset id from the representation
    (, bytes32 id) = tokenRegistry.getTokenId(_local == address(0) ? address(wrapper) : _local);

    // Router is approved
    if (!isRouterOwnershipRenounced() && !getRouterApproval(_router))
      revert ConnextHandler__addLiquidityForRouter_badRouter();

    // Asset is approved
    if (!isAssetOwnershipRenounced() && !approvedAssets[id]) revert ConnextHandler__addLiquidityForRouter_badAsset();

    ConnextLogic.addLiquidityForRouter(_amount, _local, _router, routerBalances, id, wrapper);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.11;

// ============ Internal Imports ============
import {IConnextHandler} from "../../../interfaces/IConnextHandler.sol";
import {Router} from "../Router.sol";
import {XAppConnectionClient} from "../XAppConnectionClient.sol";
import {RelayerFeeMessage} from "./RelayerFeeMessage.sol";
import {IBridgeToken} from "../../interfaces/bridge/IBridgeToken.sol";

// ============ External Imports ============
import {Home} from "../../../nomad-core/contracts/Home.sol";
import {Version0} from "../../../nomad-core/contracts/Version0.sol";
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

/**
 * @title RelayerFeeRouter
 */
contract RelayerFeeRouter is Version0, Router {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using RelayerFeeMessage for bytes29;

  // ========== Custom Errors ===========

  error RelayerFeeRouter__onlyConnext_notConnext();
  error RelayerFeeRouter__send_claimEmpty();
  error RelayerFeeRouter__send_recipientEmpty();

  // ============ Public Storage ============

  IConnextHandler public connext;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ======== Events =========

  /**
   * @notice Emitted when a fees claim has been initialized in this domain
   * @param domain The domain where to claim the fees
   * @param recipient The address of the relayer
   * @param transferIds A group of transaction ids to claim for fee bumps
   * @param remote Remote RelayerFeeRouter address
   * @param message The message sent to the destination domain
   */
  event Send(uint32 domain, address recipient, bytes32[] transferIds, bytes32 remote, bytes message);

  /**
   * @notice Emitted when the a fees claim message has arrived to this domain
   * @param originAndNonce Domain where the transfer originated and the unique identifier
   * for the message from origin to destination, combined in a single field ((origin << 32) & nonce)
   * @param origin Domain where the transfer originated
   * @param recipient The address of the relayer
   * @param transferIds A group of transaction ids to claim for fee bumps
   */
  event Receive(uint64 indexed originAndNonce, uint32 indexed origin, address indexed recipient, bytes32[] transferIds);

  /**
   * @notice Emitted when a new Connext address is set
   * @param connext The new connext address
   */
  event SetConnext(address indexed connext);

  // ============ Modifiers ============

  /**
   * @notice Restricts the caller to the local bridge router
   */
  modifier onlyConnext() {
    if (msg.sender != address(connext)) revert RelayerFeeRouter__onlyConnext_notConnext();
    _;
  }

  // ======== Initializer ========

  function initialize(address _xAppConnectionManager) public initializer {
    __XAppConnectionClient_initialize(_xAppConnectionManager);
  }

  /**
   * @notice Sets the Connext.
   * @dev Connext and relayer fee router store references to each other
   * @param _connext The address of the Connext implementation
   */
  function setConnext(address _connext) external onlyOwner {
    connext = IConnextHandler(_connext);
    emit SetConnext(_connext);
  }

  // ======== External: Send Claim =========

  /**
   * @notice Sends a request to claim the fees in the originated domain
   * @param _domain The domain where to claim the fees
   * @param _recipient The address of the relayer
   * @param _transferIds A group of transfer ids to claim for fee bumps
   */
  function send(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds
  ) external onlyConnext {
    if (_transferIds.length == 0) revert RelayerFeeRouter__send_claimEmpty();
    if (_recipient == address(0)) revert RelayerFeeRouter__send_recipientEmpty();

    // get remote RelayerFeeRouter address; revert if not found
    bytes32 remote = _mustHaveRemote(_domain);

    bytes memory message = RelayerFeeMessage.formatClaimFees(_recipient, _transferIds);

    xAppConnectionManager.home().dispatch(_domain, remote, message);

    // emit Send event
    emit Send(_domain, _recipient, _transferIds, remote, message);
  }

  // ======== External: Handle =========

  /**
   * @notice Handles an incoming message
   * @param _origin The origin domain
   * @param _nonce The unique identifier for the message from origin to destination
   * @param _sender The sender address
   * @param _message The message
   */
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external override onlyReplica onlyRemoteRouter(_origin, _sender) {
    // parse recipient and transferIds from message
    bytes29 _msg = _message.ref(0).mustBeClaimFees();

    address recipient = _msg.recipient();
    bytes32[] memory transferIds = _msg.transferIds();

    connext.claim(recipient, transferIds);

    // emit Receive event
    emit Receive(_originAndNonce(_origin, _nonce), _origin, recipient, transferIds);
  }

  /**
   * @dev explicit override for compiler inheritance
   * @dev explicit override for compiler inheritance
   * @return domain of chain on which the contract is deployed
   */
  function _localDomain() internal view override(XAppConnectionClient) returns (uint32) {
    return XAppConnectionClient._localDomain();
  }

  /**
   * @notice Internal utility function that combines
   * `_origin` and `_nonce`.
   * @dev Both origin and nonce should be less than 2^32 - 1
   * @param _origin Domain of chain where the transfer originated
   * @param _nonce The unique identifier for the message from origin to destination
   * @return Returns (`_origin` << 32) & `_nonce`
   */
  function _originAndNonce(uint32 _origin, uint32 _nonce) internal pure returns (uint64) {
    return (uint64(_origin) << 32) | _nonce;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IConnextHandler} from "../../interfaces/IConnextHandler.sol";
import {IStableSwap} from "../../interfaces/IStableSwap.sol";
import {IWrapped} from "../../interfaces/IWrapped.sol";
import {IExecutor} from "../../interfaces/IExecutor.sol";
import {LibCrossDomainProperty} from "../LibCrossDomainProperty.sol";
import {RouterPermissionsManagerInfo} from "./RouterPermissionsManagerLogic.sol";
import {AssetLogic} from "./AssetLogic.sol";

import {RelayerFeeRouter} from "../../nomad-xapps/contracts/relayer-fee-router/RelayerFeeRouter.sol";
import {ITokenRegistry, IBridgeToken} from "../../nomad-xapps/interfaces/bridge/ITokenRegistry.sol";
import {ConnextMessage} from "../../nomad-xapps/contracts/connext/ConnextMessage.sol";
import {TypedMemView} from "../../nomad-core/libs/TypedMemView.sol";
import {TypeCasts} from "../../nomad-core/contracts/XAppConnectionManager.sol";
import {Home} from "../../nomad-core/contracts/Home.sol";

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {SafeERC20Upgradeable, AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library ConnextLogic {
  // ============ Libraries ============
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using ConnextMessage for bytes29;

  bytes32 internal constant EMPTY = hex"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

  // ============ Errors ============

  error ConnextLogic__addAssetId_alreadyAdded();
  error ConnextLogic__removeAssetId_notAdded();
  error ConnextLogic__addRelayer_alreadyApproved();
  error ConnextLogic__removeRelayer_notApproved();
  error ConnextLogic__setMaxRoutersPerTransfer_invalidMaxRoutersPerTransfer();
  error ConnextLogic__reconcile_invalidAction();
  error ConnextLogic__reconcile_alreadyReconciled();
  error ConnextLogic__removeLiquidity_recipientEmpty();
  error ConnextLogic__removeLiquidity_amountIsZero();
  error ConnextLogic__removeLiquidity_insufficientFunds();
  error ConnextLogic__xcall_wrongDomain();
  error ConnextLogic__xcall_emptyTo();
  error ConnextLogic__xcall_notSupportedAsset();
  error ConnextLogic__xcall_relayerFeeIsZero();
  error ConnextLogic__execute_unapprovedRelayer();
  error ConnextLogic__execute_maxRoutersExceeded();
  error ConnextLogic__execute_alreadyExecuted();
  error ConnextLogic__execute_notSupportedRouter();
  error ConnextLogic__execute_invalidRouterSignature();
  error ConnextLogic__initiateClaim_notRelayer(bytes32 transferId);
  error ConnextLogic__bumpTransfer_invalidTransfer();
  error ConnextLogic__bumpTransfer_valueIsZero();

  // ============ Structs ============

  struct XCallLibArgs {
    IConnextHandler.XCallArgs xCallArgs;
    IWrapped wrapper;
    uint256 nonce;
    ITokenRegistry tokenRegistry;
    uint256 domain;
    Home home;
    bytes32 remote;
  }

  struct XCalledEventArgs {
    address transactingAssetId;
    uint256 amount;
    uint256 bridgedAmt;
    address bridged;
  }

  struct ExecuteLibArgs {
    IConnextHandler.ExecuteArgs executeArgs;
    bool isRouterOwnershipRenounced;
    uint256 maxRoutersPerTransfer;
    ITokenRegistry tokenRegistry;
    IWrapped wrapper;
    IExecutor executor;
    uint256 liquidityFeeNumerator;
    uint256 liquidityFeeDenominator;
  }

  // ============ Events ============

  /**
   * @notice Emitted when a new stable-swap AMM is added for the local <> adopted token
   * @param canonicalId - The canonical identifier of the token the local <> adopted AMM is for
   * @param domain - The domain of the canonical token for the local <> adopted amm
   * @param swapPool - The address of the AMM
   * @param caller - The account that called the function
   */
  event StableSwapAdded(bytes32 canonicalId, uint32 domain, address swapPool, address caller);

  /**
   * @notice Emitted when a new asset is added
   * @param canonicalId - The canonical identifier of the token the local <> adopted AMM is for
   * @param domain - The domain of the canonical token for the local <> adopted amm
   * @param adoptedAsset - The address of the adopted (user-expected) asset
   * @param supportedAsset - The address of the whitelisted asset. If the native asset is to be whitelisted,
   * the address of the wrapped version will be stored
   * @param caller - The account that called the function
   */
  event AssetAdded(bytes32 canonicalId, uint32 domain, address adoptedAsset, address supportedAsset, address caller);

  /**
   * @notice Emitted when an asset is removed from whitelists
   * @param canonicalId - The canonical identifier of the token removed
   * @param caller - The account that called the function
   */
  event AssetRemoved(bytes32 canonicalId, address caller);

  /**
   * @notice Emitted when a rlayer is added or removed from whitelists
   * @param relayer - The relayer address to be added or removed
   * @param caller - The account that called the function
   */
  event RelayerAdded(address relayer, address caller);

  /**
   * @notice Emitted when a rlayer is added or removed from whitelists
   * @param relayer - The relayer address to be added or removed
   * @param caller - The account that called the function
   */
  event RelayerRemoved(address relayer, address caller);

  /**
   * @notice Emitted when a router withdraws liquidity from the contract
   * @param router - The router you are removing liquidity from
   * @param to - The address the funds were withdrawn to
   * @param local - The address of the token withdrawn
   * @param amount - The amount of liquidity withdrawn
   * @param caller - The account that called the function
   */
  event LiquidityRemoved(address indexed router, address to, address local, uint256 amount, address caller);

  /**
   * @notice Emitted when a router adds liquidity to the contract
   * @param router - The address of the router the funds were credited to
   * @param local - The address of the token added (all liquidity held in local asset)
   * @param amount - The amount of liquidity added
   * @param caller - The account that called the function
   */
  event LiquidityAdded(address indexed router, address local, bytes32 canonicalId, uint256 amount, address caller);

  /**
   * @notice Emitted when the maxRoutersPerTransfer variable is updated
   * @param maxRoutersPerTransfer - The maxRoutersPerTransfer new value
   * @param caller - The account that called the function
   */
  event MaxRoutersPerTransferUpdated(uint256 maxRoutersPerTransfer, address caller);

  /**
   * @notice Emitted when `xcall` is called on the origin domain
   */
  event XCalled(
    bytes32 indexed transferId,
    IConnextHandler.XCallArgs xcallArgs,
    XCalledEventArgs args,
    uint256 nonce,
    bytes message,
    address caller
  );

  /**
   * @notice Emitted when `execute` is called on the destination chain
   * @dev `execute` may be called when providing fast liquidity *or* when processing a reconciled transfer
   * @param transferId - The unique identifier of the crosschain transfer
   * @param to - The CallParams.to provided, created as indexed parameter
   * @param args - The ExecuteArgs provided to the function
   * @param transactingAsset - The asset the to gets or the external call is executed with. Should be the
   * adopted asset on that chain.
   * @param transactingAmount - The amount of transferring asset the to address receives or the external call is
   * executed with
   * @param caller - The account that called the function
   */
  event Executed(
    bytes32 indexed transferId,
    address indexed to,
    IConnextHandler.ExecuteArgs args,
    address transactingAsset,
    uint256 transactingAmount,
    address caller
  );

  /**
   * @notice Emitted when `reconciled` is called by the bridge on the destination domain
   * @param transferId - The unique identifier of the crosschain transaction
   * @param origin - The origin domain of the transfer
   * @param routers - The CallParams.recipient provided, created as indexed parameter
   * @param asset - The asset that was provided by the bridge
   * @param amount - The amount that was provided by the bridge
   * @param caller - The account that called the function
   */
  event Reconciled(
    bytes32 indexed transferId,
    uint32 indexed origin,
    address[] routers,
    address asset,
    uint256 amount,
    address caller
  );

  /**
   * @notice Emitted when `bumpTransfer` is called by an user on the origin domain
   * @param transferId - The unique identifier of the crosschain transaction
   * @param relayerFee - The updated amount of relayer fee in native asset
   * @param caller - The account that called the function
   */
  event TransferRelayerFeesUpdated(bytes32 indexed transferId, uint256 relayerFee, address caller);

  /**
   * @notice Emitted when `initiateClaim` is called on the destination chain
   * @param domain - Domain to claim funds on
   * @param recipient - Address on origin chain to send claimed funds to
   * @param caller - The account that called the function
   * @param transferIds - TransferIds to claim
   */
  event InitiatedClaim(uint32 indexed domain, address indexed recipient, address caller, bytes32[] transferIds);

  /**
   * @notice Emitted when `claim` is called on the origin domain
   * @param recipient - Address on origin chain to send claimed funds to
   * @param total - Total amount claimed
   * @param transferIds - TransferIds to claim
   */
  event Claimed(address indexed recipient, uint256 total, bytes32[] transferIds);

  // ============ Admin Functions ============

  /**
   * @notice Used to add an AMM for adopted <> local assets
   * @param _canonical - The canonical TokenId to add (domain and id)
   * @param _stableSwap - The address of the amm to add
   */
  function addStableSwapPool(
    ConnextMessage.TokenId calldata _canonical,
    address _stableSwap,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools
  ) external {
    // Update the pool mapping
    _adoptedToLocalPools[_canonical.id] = IStableSwap(_stableSwap);

    emit StableSwapAdded(_canonical.id, _canonical.domain, _stableSwap, msg.sender);
  }

  /**
   * @notice Used to add assets on same chain as contract that can be transferred.
   * @param _canonical - The canonical TokenId to add (domain and id)
   * @param _adoptedAssetId - The used asset id for this domain (i.e. PoS USDC for
   * polygon)
   */
  function addAssetId(
    ConnextMessage.TokenId calldata _canonical,
    address _adoptedAssetId,
    address _wrapper,
    mapping(bytes32 => bool) storage _approvedAssets,
    mapping(address => ConnextMessage.TokenId) storage _adoptedToCanonical,
    mapping(bytes32 => address) storage _canonicalToAdopted
  ) external {
    // Sanity check: needs approval
    if (_approvedAssets[_canonical.id]) revert ConnextLogic__addAssetId_alreadyAdded();

    // Update approved assets mapping
    _approvedAssets[_canonical.id] = true;

    address supported = _adoptedAssetId == address(0) ? _wrapper : _adoptedAssetId;

    // Update the adopted mapping
    _adoptedToCanonical[supported] = _canonical;

    // Update the canonical mapping
    _canonicalToAdopted[_canonical.id] = supported;

    // Emit event
    emit AssetAdded(_canonical.id, _canonical.domain, _adoptedAssetId, supported, msg.sender);
  }

  /**
   * @notice Used to remove assets from the whitelist
   * @param _canonicalId - Token id to remove
   * @param _adoptedAssetId - Corresponding adopted asset to remove
   */
  function removeAssetId(
    bytes32 _canonicalId,
    address _adoptedAssetId,
    address _wrapper,
    mapping(bytes32 => bool) storage _approvedAssets,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools,
    mapping(address => ConnextMessage.TokenId) storage _adoptedToCanonical
  ) external {
    // Sanity check: already approval
    if (!_approvedAssets[_canonicalId]) revert ConnextLogic__removeAssetId_notAdded();

    // Update mapping
    delete _approvedAssets[_canonicalId];

    // Update pools
    delete _adoptedToLocalPools[_canonicalId];

    // Update adopted mapping
    delete _adoptedToCanonical[_adoptedAssetId == address(0) ? _wrapper : _adoptedAssetId];

    // Emit event
    emit AssetRemoved(_canonicalId, msg.sender);
  }

  /**
   * @notice Used to add approved relayer
   * @param _relayer - The relayer address to add
   */
  function addRelayer(address _relayer, mapping(address => bool) storage _approvedRelayers) external {
    if (_approvedRelayers[_relayer]) revert ConnextLogic__addRelayer_alreadyApproved();
    _approvedRelayers[_relayer] = true;

    emit RelayerAdded(_relayer, msg.sender);
  }

  /**
   * @notice Used to remove approved relayer
   * @param _relayer - The relayer address to remove
   */
  function removeRelayer(address _relayer, mapping(address => bool) storage _approvedRelayers) external {
    if (!_approvedRelayers[_relayer]) revert ConnextLogic__removeRelayer_notApproved();
    delete _approvedRelayers[_relayer];

    emit RelayerRemoved(_relayer, msg.sender);
  }

  /**
   * @notice Used to set the max amount of routers a payment can be routed through
   * @param _newMax The new max amount of routers
   */
  function setMaxRoutersPerTransfer(uint256 _newMax, uint256 _currentMax) external {
    if (_newMax == 0 || _newMax == _currentMax)
      revert ConnextLogic__setMaxRoutersPerTransfer_invalidMaxRoutersPerTransfer();

    emit MaxRoutersPerTransferUpdated(_newMax, msg.sender);
  }

  // ============ Functions ============

  /**
   * @notice Contains the logic to verify + increment a given routers liquidity
   * @dev The liquidity will be held in the local asset, which is the representation if you
   * are *not* on the canonical domain, and the canonical asset otherwise.
   * @param _amount - The amount of liquidity to add for the router
   * @param _local - The address of the nomad representation of the asset
   * @param _router - The router you are adding liquidity on behalf of
   * @param _canonicalId - Canonical asset id from the representation
   */
  function addLiquidityForRouter(
    uint256 _amount,
    address _local,
    address _router,
    mapping(address => mapping(address => uint256)) storage _routerBalances,
    bytes32 _canonicalId,
    IWrapped _wrapper
  ) external {
    // Transfer funds to contract
    (address asset, uint256 received) = AssetLogic.handleIncomingAsset(_local, _amount, 0, _wrapper);

    // Update the router balances. Happens after pulling funds to account for
    // the fee on transfer tokens
    _routerBalances[_router][asset] += received;

    // Emit event
    emit LiquidityAdded(_router, asset, _canonicalId, received, msg.sender);
  }

  /**
   * @notice This is used by any router to decrease their available liquidity for a given asset.
   * @param _amount - The amount of liquidity to remove for the router
   * @param _local - The address of the asset you're removing liquidity from. If removing liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   * @param _recipient The address that will receive the liquidity being removed
   */
  function removeLiquidity(
    uint256 _amount,
    address _local,
    address _recipient,
    mapping(address => mapping(address => uint256)) storage _routerBalances,
    IWrapped _wrapper
  ) external {
    // Sanity check: to is sensible
    if (_recipient == address(0)) revert ConnextLogic__removeLiquidity_recipientEmpty();

    // Sanity check: nonzero amounts
    if (_amount == 0) revert ConnextLogic__removeLiquidity_amountIsZero();

    uint256 routerBalance = _routerBalances[msg.sender][_local];
    // Sanity check: amount can be deducted for the router
    if (routerBalance < _amount) revert ConnextLogic__removeLiquidity_insufficientFunds();

    // Update router balances
    unchecked {
      _routerBalances[msg.sender][_local] = routerBalance - _amount;
    }

    // Transfer from contract to specified to
    AssetLogic.transferAssetFromContract(_local, _recipient, _amount, _wrapper);

    // Emit event
    emit LiquidityRemoved(msg.sender, _recipient, _local, _amount, msg.sender);
  }

  /**
   * @notice This function is called ConnextHandler when a user who is looking to bridge funds
   * @param _args - The XCallArgs
   * @param _adoptedToCanonical - Mapping of canonical to adopted assets on this domain
   * @param _adoptedToLocalPools - Mapping holding the AMMs for swapping in and out of local assets
   * @param _relayerFees - Mapping of relayer fee for a transfer
   * @return The transfer id of the crosschain transfer
   */
  function xcall(
    XCallLibArgs calldata _args,
    mapping(address => ConnextMessage.TokenId) storage _adoptedToCanonical,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools,
    mapping(bytes32 => uint256) storage _relayerFees
  ) external returns (bytes32, uint256) {
    _xcallSanityChecks(_args);

    // get the true transacting asset id (using wrapped native instead native)
    (bytes32 transferId, bytes memory message, XCalledEventArgs memory eventArgs) = _xcallProcess(
      _args,
      _adoptedToCanonical,
      _adoptedToLocalPools
    );

    // Store the relayer fee
    _relayerFees[transferId] = _args.xCallArgs.relayerFee;

    // emit event
    emit XCalled(transferId, _args.xCallArgs, eventArgs, _args.nonce, message, msg.sender);

    return (transferId, _args.nonce + 1);
  }

  /**
   * @notice Called via `handle` to manage funds associated with a transaction
   * @dev Will either (a) credit router or (b) make funds available for execution. Don't
   * include execution here
   */
  function reconcile(
    uint32 _origin,
    bytes memory _message,
    mapping(bytes32 => bool) storage _reconciledTransfers,
    ITokenRegistry _tokenRegistry,
    mapping(bytes32 => address[]) storage _routedTransfers,
    mapping(address => mapping(address => uint256)) storage _routerBalances
  ) external {
    // parse tokenId and action from message
    bytes29 msg_ = _message.ref(0).mustBeMessage();
    bytes29 tokenId = msg_.tokenId();
    bytes29 action = msg_.action();

    // assert the action is valid
    if (!action.isTransfer()) {
      revert ConnextLogic__reconcile_invalidAction();
    }

    // load the transferId
    bytes32 transferId = action.transferId();

    // ensure the transaction has not been handled
    if (_reconciledTransfers[transferId]) {
      revert ConnextLogic__reconcile_alreadyReconciled();
    }

    // get the token contract for the given tokenId on this chain
    // (if the token is of remote origin and there is
    // no existing representation token contract, the TokenRegistry will
    // deploy a new one)
    address token = _tokenRegistry.ensureLocalToken(tokenId.domain(), tokenId.id());

    // load amount once
    uint256 amount = action.amnt();

    // NOTE: tokenId + amount must be in plaintext in message so funds can
    // *only* be minted by `handle`. They are still used in the generation of
    // the transferId so routers must provide them correctly to be reimbursed

    // TODO: do we need to keep this
    bytes32 details = action.detailsHash();

    // if the token is of remote origin, mint the tokens. will either
    // - be credited to router (fast liquidity)
    // - be reserved for execution (slow liquidity)
    if (!_tokenRegistry.isLocalOrigin(token)) {
      IBridgeToken(token).mint(address(this), amount);
      // Tell the token what its detailsHash is
      IBridgeToken(token).setDetailsHash(details);
    }
    // NOTE: if the token is of local origin, it means it was escrowed
    // in this contract at xcall

    // mark the transfer as reconciled
    _reconciledTransfers[transferId] = true;

    // get the transfer
    address[] storage routers = _routedTransfers[transferId];

    uint256 pathLen = routers.length;
    if (pathLen != 0) {
      // fast liquidity path
      // credit the router the asset
      uint256 routerAmt = amount / pathLen;
      for (uint256 i; i < pathLen; ) {
        _routerBalances[routers[i]][token] += routerAmt;
        unchecked {
          i++;
        }
      }
    }

    emit Reconciled(transferId, _origin, routers, token, amount, msg.sender);
  }

  /**
   * @notice Called on the destination domain to disburse correct assets to end recipient
   * and execute any included calldata
   * @dev Can be called prior to or after `handle`, depending if fast liquidity is being
   * used.
   */
  function execute(
    ExecuteLibArgs calldata _args,
    mapping(bytes32 => address[]) storage _routedTransfers,
    mapping(bytes32 => bool) storage _reconciledTransfers,
    mapping(address => mapping(address => uint256)) storage _routerBalances,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools,
    mapping(bytes32 => address) storage _canonicalToAdopted,
    RouterPermissionsManagerInfo storage _routerInfo,
    mapping(bytes32 => address) storage _transferRelayer
  ) external returns (bytes32) {
    (bytes32 transferId, bool reconciled) = _executeSanityChecks(
      _args,
      _transferRelayer,
      _reconciledTransfers,
      _routerInfo.approvedRouters
    );

    // execute router liquidity when this is a fast transfer
    (uint256 amount, address adopted) = _handleExecuteLiquidity(
      transferId,
      !reconciled,
      _args,
      _routedTransfers,
      _routerBalances,
      _adoptedToLocalPools,
      _canonicalToAdopted
    );

    // execute the transaction
    _handleExecuteTransaction(_args, amount, adopted, transferId, reconciled);

    // Set the relayer for this transaction to allow for future claim
    _transferRelayer[transferId] = msg.sender;

    // emit event
    emit Executed(transferId, _args.executeArgs.params.to, _args.executeArgs, adopted, amount, msg.sender);

    return transferId;
  }

  /**
   * @notice Called by relayer when they want to claim owed funds on a given domain
   * @dev Domain should be the origin domain of all the transfer ids
   * @param _domain - domain to claim funds on
   * @param _recipient - address on origin chain to send claimed funds to
   * @param _transferIds - transferIds to claim
   * @param _relayerFeeRouter - The local nomad relayer fee router
   * @param _transferRelayer - Mapping of transactionIds to relayer
   */
  function initiateClaim(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds,
    RelayerFeeRouter _relayerFeeRouter,
    mapping(bytes32 => address) storage _transferRelayer
  ) external {
    // Ensure the relayer can claim all transfers specified
    for (uint256 i; i < _transferIds.length; ) {
      if (_transferRelayer[_transferIds[i]] != msg.sender)
        revert ConnextLogic__initiateClaim_notRelayer(_transferIds[i]);
      unchecked {
        i++;
      }
    }

    // Send transferIds via nomad
    _relayerFeeRouter.send(_domain, _recipient, _transferIds);

    emit InitiatedClaim(_domain, _recipient, msg.sender, _transferIds);
  }

  /**
   * @notice Pays out a relayer for the given fees
   * @dev Called by the RelayerFeeRouter.handle message. The validity of the transferIds is
   * asserted before dispatching the message.
   * @param _recipient - address on origin chain to send claimed funds to
   * @param _transferIds - transferIds to claim
   * @param _relayerFees - Mapping of transactionIds to fee
   */
  function claim(
    address _recipient,
    bytes32[] calldata _transferIds,
    mapping(bytes32 => uint256) storage _relayerFees
  ) external {
    // Tally amounts owed
    uint256 total;
    for (uint256 i; i < _transferIds.length; ) {
      total += _relayerFees[_transferIds[i]];
      _relayerFees[_transferIds[i]] = 0;
      unchecked {
        i++;
      }
    }

    AddressUpgradeable.sendValue(payable(_recipient), total);

    emit Claimed(_recipient, total, _transferIds);
  }

  /**
   * @notice Anyone can call this function on the origin domain to increase the relayer fee for a transfer.
   * @param _transferId - The unique identifier of the crosschain transaction
   */
  function bumpTransfer(bytes32 _transferId, mapping(bytes32 => uint256) storage relayerFees) external {
    if (msg.value == 0) revert ConnextLogic__bumpTransfer_valueIsZero();

    relayerFees[_transferId] += msg.value;

    emit TransferRelayerFeesUpdated(_transferId, relayerFees[_transferId], msg.sender);
  }

  // ============ Private Functions ============

  /**
   * @notice Performs some sanity checks for `execute`
   * @dev Need this to prevent stack too deep
   */
  function _executeSanityChecks(
    ExecuteLibArgs calldata _args,
    mapping(bytes32 => address) storage _transferRelayer,
    mapping(bytes32 => bool) storage _reconciledTransfers,
    mapping(address => bool) storage _approvedRouters
  ) private returns (bytes32, bool) {
    // get number of facilitating routers
    uint256 pathLength = _args.executeArgs.routers.length;

    // make sure number of routers is valid
    if (pathLength > _args.maxRoutersPerTransfer) revert ConnextLogic__execute_maxRoutersExceeded();

    // get transfer id
    bytes32 transferId = _getTransferId(_args);

    // get the payload the router should have signed
    bytes32 routerHash = keccak256(abi.encode(transferId, pathLength));

    // make sure routers are all approved if needed
    for (uint256 i; i < pathLength; ) {
      if (!_args.isRouterOwnershipRenounced && !_approvedRouters[_args.executeArgs.routers[i]]) {
        revert ConnextLogic__execute_notSupportedRouter();
      }
      if (_args.executeArgs.routers[i] != _recoverSignature(routerHash, _args.executeArgs.routerSignatures[i])) {
        revert ConnextLogic__execute_invalidRouterSignature();
      }
      unchecked {
        i++;
      }
    }

    // require this transfer has not already been executed
    if (_transferRelayer[transferId] != address(0)) {
      revert ConnextLogic__execute_alreadyExecuted();
    }

    // get reconciled record
    bool reconciled = _reconciledTransfers[transferId];

    return (transferId, reconciled);
  }

  /**
   * @notice Calculates fast transfer amount.
   * @param _amount Transfer amount
   * @param _liquidityFeeNum Liquidity fee numerator
   * @param _liquidityFeeDen Liquidity fee denominator
   */
  function _getFastTransferAmount(
    uint256 _amount,
    uint256 _liquidityFeeNum,
    uint256 _liquidityFeeDen
  ) private pure returns (uint256) {
    return (_amount * _liquidityFeeNum) / _liquidityFeeDen;
  }

  /**
   * @notice Performs some sanity checks for `xcall`
   * @dev Need this to prevent stack too deep
   */
  function _xcallSanityChecks(XCallLibArgs calldata _args) private {
    // ensure this is the right domain
    if (_args.xCallArgs.params.originDomain != _args.domain) {
      revert ConnextLogic__xcall_wrongDomain();
    }

    // ensure theres a recipient defined
    if (_args.xCallArgs.params.to == address(0)) {
      revert ConnextLogic__xcall_emptyTo();
    }
  }

  /**
   * @notice Processes an `xcall`
   * @dev Need this to prevent stack too deep
   */
  function _xcallProcess(
    XCallLibArgs calldata _args,
    mapping(address => ConnextMessage.TokenId) storage _adoptedToCanonical,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools
  )
    private
    returns (
      bytes32,
      bytes memory,
      XCalledEventArgs memory
    )
  {
    address transactingAssetId = _args.xCallArgs.transactingAssetId == address(0)
      ? address(_args.wrapper)
      : _args.xCallArgs.transactingAssetId;

    // check that the asset is supported -- can be either adopted or local
    ConnextMessage.TokenId memory canonical = _adoptedToCanonical[transactingAssetId];
    if (canonical.id == bytes32(0)) {
      revert ConnextLogic__xcall_notSupportedAsset();
    }

    // transfer funds of transacting asset to the contract from user
    // NOTE: will wrap any native asset transferred to wrapped-native automatically
    (, uint256 amount) = AssetLogic.handleIncomingAsset(
      _args.xCallArgs.transactingAssetId,
      _args.xCallArgs.amount,
      _args.xCallArgs.relayerFee,
      _args.wrapper
    );

    // swap to the local asset from adopted
    (uint256 bridgedAmt, address bridged) = AssetLogic.swapToLocalAssetIfNeeded(
      canonical,
      _adoptedToLocalPools[canonical.id],
      _args.tokenRegistry,
      transactingAssetId,
      amount
    );

    bytes32 transferId = _getTransferId(_args, canonical);

    bytes memory message = _formatMessage(_args, bridged, transferId, bridgedAmt);
    _args.home.dispatch(_args.xCallArgs.params.destinationDomain, _args.remote, message);

    return (
      transferId,
      message,
      XCalledEventArgs({
        transactingAssetId: transactingAssetId,
        amount: amount,
        bridgedAmt: bridgedAmt,
        bridged: bridged
      })
    );
  }

  /**
   * @notice Calculates a transferId based on `execute` arguments
   * @dev Need this to prevent stack too deep
   */
  function _getTransferId(ExecuteLibArgs calldata _args) private view returns (bytes32) {
    (uint32 tokenDomain, bytes32 tokenId) = _args.tokenRegistry.getTokenId(_args.executeArgs.local);

    return
      keccak256(
        abi.encode(
          _args.executeArgs.nonce,
          _args.executeArgs.params,
          _args.executeArgs.originSender,
          tokenId,
          tokenDomain,
          _args.executeArgs.amount
        )
      );
  }

  /**
   * @notice Calculates a transferId based on `xcall` arguments
   * @dev Need this to prevent stack too deep
   */
  function _getTransferId(XCallLibArgs calldata _args, ConnextMessage.TokenId memory _canonical)
    private
    view
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          _args.nonce,
          _args.xCallArgs.params,
          msg.sender,
          _canonical.id,
          _canonical.domain,
          _args.xCallArgs.amount
        )
      );
  }

  /**
   * @notice Formats a nomad message generated by `xcall`
   * @dev Need this to prevent stack too deep
   */
  function _formatMessage(
    XCallLibArgs calldata _args,
    address _asset,
    bytes32 _transferId,
    uint256 _amount
  ) private returns (bytes memory) {
    // get token
    IBridgeToken token = IBridgeToken(_asset);

    // declare details
    bytes32 detailsHash;

    if (_args.tokenRegistry.isLocalOrigin(_asset)) {
      // TODO: do we want to store a mapping of custodied token balances here?

      // token is local, custody token on this chain
      // query token contract for details and calculate detailsHash
      detailsHash = ConnextMessage.formatDetailsHash(token.name(), token.symbol(), token.decimals());
    } else {
      // if the token originates on a remote chain,
      // burn the representation tokens on this chain
      if (_amount > 0) {
        token.burn(msg.sender, _amount);
      }
      detailsHash = token.detailsHash();
    }

    // format action
    bytes29 action = ConnextMessage.formatTransfer(
      TypeCasts.addressToBytes32(_args.xCallArgs.params.to),
      _amount,
      detailsHash,
      _transferId
    );

    // get the tokenID
    (uint32 domain, bytes32 id) = _args.tokenRegistry.getTokenId(_asset);

    // format token id
    bytes29 tokenId = ConnextMessage.formatTokenId(domain, id);

    // send message
    return ConnextMessage.formatMessage(tokenId, action);
  }

  /**
   * @notice Process the transfer, and calldata if needed, when calling `execute`
   * @dev Need this to prevent stack too deep
   */
  function _handleExecuteTransaction(
    ExecuteLibArgs calldata _args,
    uint256 _amount,
    address _adopted,
    bytes32 _transferId,
    bool _reconciled
  ) private {
    // execute the the transaction
    if (keccak256(_args.executeArgs.params.callData) == EMPTY) {
      // no call data, send funds to the user
      AssetLogic.transferAssetFromContract(_adopted, _args.executeArgs.params.to, _amount, _args.wrapper);
    } else {
      // execute calldata w/funds
      AssetLogic.transferAssetFromContract(_adopted, address(_args.executor), _amount, _args.wrapper);
      _args.executor.execute(
        _transferId,
        _amount,
        payable(_args.executeArgs.params.to),
        _adopted,
        _reconciled
          ? LibCrossDomainProperty.formatDomainAndSenderBytes(
            _args.executeArgs.params.originDomain,
            _args.executeArgs.originSender
          )
          : LibCrossDomainProperty.EMPTY_BYTES,
        _args.executeArgs.params.callData
      );
    }
  }

  /**
   * @notice Execute liquidity process used when calling `execute`
   * @dev Need this to prevent stack too deep
   */
  function _handleExecuteLiquidity(
    bytes32 _transferId,
    bool _isFast,
    ExecuteLibArgs calldata _args,
    mapping(bytes32 => address[]) storage _routedTransfers,
    mapping(address => mapping(address => uint256)) storage _routerBalances,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools,
    mapping(bytes32 => address) storage _canonicalToAdopted
  ) private returns (uint256, address) {
    uint256 toSwap = _args.executeArgs.amount;
    uint256 pathLen = _args.executeArgs.routers.length;
    if (_isFast) {
      // this is the fast liquidity path
      // ensure the router is whitelisted

      // calculate amount with fast liquidity fee
      toSwap = _getFastTransferAmount(
        _args.executeArgs.amount,
        _args.liquidityFeeNumerator,
        _args.liquidityFeeDenominator
      );

      // TODO: validate routers signature on path / transferId

      // store the routers address
      _routedTransfers[_transferId] = _args.executeArgs.routers;

      // for each router, assert they are approved, and deduct liquidity
      uint256 routerAmount = toSwap / pathLen;
      for (uint256 i; i < pathLen; ) {
        // decrement routers liquidity
        _routerBalances[_args.executeArgs.routers[i]][_args.executeArgs.local] -= routerAmount;

        unchecked {
          i++;
        }
      }
    }

    // swap out of mad* asset into adopted asset if needed
    return
      AssetLogic.swapFromLocalAssetIfNeeded(
        _canonicalToAdopted,
        _adoptedToLocalPools,
        _args.tokenRegistry,
        _args.executeArgs.local,
        toSwap
      );
  }

  /**
   * @notice Holds the logic to recover the signer from an encoded payload.
   * @dev Will hash and convert to an eth signed message.
   * @param _signed The hash that was signed
   * @param _sig The signature you are recovering the signer from
   */
  function _recoverSignature(bytes32 _signed, bytes calldata _sig) internal pure returns (address) {
    // Recover
    return ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(_signed), _sig);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

// TODO: need a correct interface here
interface IWrapped {
  function deposit() external payable;

  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IExecutor {
  event Executed(
    bytes32 indexed transferId,
    address indexed to,
    address assetId,
    uint256 amount,
    bytes _properties,
    bytes callData,
    bytes returnData,
    bool success
  );

  function getConnext() external returns (address);

  function originSender() external returns (address);

  function origin() external returns (uint32);

  function execute(
    bytes32 _transferId,
    uint256 _amount,
    address payable _to,
    address _assetId,
    bytes memory _properties,
    bytes calldata _callData
  ) external payable returns (bool success, bytes memory returnData);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IExecutor} from "../interfaces/IExecutor.sol";

import {LibCrossDomainProperty, TypedMemView} from "../lib/LibCrossDomainProperty.sol";

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Executor
 * @author Connext <[email protected]>
 * @notice This library contains an `execute` function that is callabale by
 * an associated Connext contract. This is used to execute
 * arbitrary calldata on a receiving chain.
 */
contract Executor is IExecutor {
  // ============ Libraries =============

  using TypedMemView for bytes29;
  using TypedMemView for bytes;

  // ============ Properties =============

  address private immutable connext;
  bytes private properties = LibCrossDomainProperty.EMPTY_BYTES;

  // ============ Constructor =============

  constructor(address _connext) {
    connext = _connext;
  }

  // ============ Modifiers =============

  /**
   * @notice Errors if the sender is not Connext
   */
  modifier onlyConnext() {
    require(msg.sender == connext, "#OC:027");
    _;
  }

  // ============ Public Functions =============

  /**
   * @notice Returns the connext contract address (only address that can
   * call the `execute` function)
   * @return The address of the associated connext contract
   */
  function getConnext() external view override returns (address) {
    return connext;
  }

  /**
   * @notice Allows a `_to` contract to access origin domain sender (i.e. msg.sender of `xcall`)
   * @dev These properties are set via reentrancy a la L2CrossDomainMessenger from
   * optimism
   */
  function originSender() external view override returns (address) {
    // The following will revert if it is empty
    bytes29 _parsed = LibCrossDomainProperty.parseDomainAndSenderBytes(properties);
    return LibCrossDomainProperty.sender(_parsed);
  }

  /**
   * @notice Allows a `_to` contract to access origin domain (i.e. domain of `xcall`)
   * @dev These properties are set via reentrancy a la L2CrossDomainMessenger from
   * optimism
   */
  function origin() external view override returns (uint32) {
    // The following will revert if it is empty
    bytes29 _parsed = LibCrossDomainProperty.parseDomainAndSenderBytes(properties);
    return LibCrossDomainProperty.domain(_parsed);
  }

  /**
   * @notice Executes some arbitrary call data on a given address. The
   * call data executes can be payable, and will have `amount` sent
   * along with the function (or approved to the contract). If the
   * call fails, rather than reverting, funds are sent directly to
   * some provided fallback address
   * @param _transferId Unique identifier of transaction id that necessitated
   * calldata execution
   * @param _amount The amount to approve or send with the call
   * @param _to The address to execute the calldata on
   * @param _assetId The assetId of the funds to approve to the contract or
   * send along with the call
   * @param _properties The origin properties
   * @param _callData The data to execute
   */
  function execute(
    bytes32 _transferId,
    uint256 _amount,
    address payable _to,
    address _assetId,
    bytes memory _properties,
    bytes calldata _callData
  ) external payable override onlyConnext returns (bool, bytes memory) {
    // If it is not ether, approve the callTo
    // We approve here rather than transfer since many external contracts
    // simply require an approval, and it is unclear if they can handle
    // funds transferred directly to them (i.e. Uniswap)
    bool isNative = _assetId == address(0);
    if (!isNative) {
      SafeERC20Upgradeable.safeIncreaseAllowance(IERC20Upgradeable(_assetId), _to, _amount);
    }

    // Check if the callTo is a contract
    bool success;
    bytes memory returnData;
    require(AddressUpgradeable.isContract(_to), "!contract");

    // If it should set the properties, set them.
    // NOTE: safe to set the properties always because modifier will revert if
    // it is the wrong type on conversion, and revert occurs with empty type as
    // well
    properties = _properties;

    // Try to execute the callData
    // the low level call will return `false` if its execution reverts
    (success, returnData) = _to.call{value: isNative ? _amount : 0}(_callData);

    // Unset properties
    properties = LibCrossDomainProperty.EMPTY_BYTES;

    // Handle failure cases
    if (!success && !isNative) {
      // Decrease allowance
      SafeERC20Upgradeable.safeDecreaseAllowance(IERC20Upgradeable(_assetId), _to, _amount);
    }

    // Emit event
    emit Executed(_transferId, _to, _assetId, _amount, _properties, _callData, returnData, success);
    return (success, returnData);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {RouterPermissionsManagerLogic, RouterPermissionsManagerInfo} from "./lib/Connext/RouterPermissionsManagerLogic.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice
 * This contract is designed to manage router access, meaning it maintains the
 * router recipients, owners, and the router whitelist itself. It does *not* manage router balances
 * as asset management is out of scope of this contract.
 *
 * As a router, there are three important permissions:
 * `router` - this is the address that will sign bids sent to the sequencer
 * `routerRecipient` - this is the address that receives funds when liquidity is withdrawn
 * `routerOwner` - this is the address permitted to update recipients and propose new owners
 *
 * In cases where the owner is not set, the caller should be the `router` itself. In cases where the
 * `routerRecipient` is not set, the funds can be removed to anywhere.
 *
 * When setting a new `routerOwner`, the current owner (or router) must create a proposal, which
 * can be accepted by the proposed owner after the delay period. If the proposed owner is the empty
 * address, then it must be accepted by the current owner.
 */
abstract contract RouterPermissionsManager is Initializable {
  // ============ Private storage =============

  uint256 private _delay;

  // ============ Public storage =============

  RouterPermissionsManagerInfo internal routerInfo;

  // ============ Initialize =============

  /**
   * @dev Initializes the contract setting the deployer as the initial
   */
  function __RouterPermissionsManager_init() internal onlyInitializing {
    __RouterPermissionsManager_init_unchained();
  }

  function __RouterPermissionsManager_init_unchained() internal onlyInitializing {
    _delay = 7 days;
  }

  // ============ Public methods ==============

  /**
   * @notice Returns the approved router for the given router address
   * @param _router The relevant router address
   */
  function getRouterApproval(address _router) public view returns (bool) {
    return routerInfo.approvedRouters[_router];
  }

  /**
   * @notice Returns the recipient for the specified router
   * @dev The recipient (if set) receives all funds when router liquidity is removed
   * @param _router The relevant router address
   */
  function getRouterRecipient(address _router) public view returns (address) {
    return routerInfo.routerRecipients[_router];
  }

  /**
   * @notice Returns the router owner if it is set, or the router itself if not
   * @dev Uses logic function here to handle the case where router owner is not set.
   * Other getters within this interface use explicitly the stored value
   * @param _router The relevant router address
   */
  function getRouterOwner(address _router) public view returns (address) {
    return RouterPermissionsManagerLogic.getRouterOwner(_router, routerInfo.routerOwners);
  }

  /**
   * @notice Returns the currently proposed router owner
   * @dev All routers must wait for the delay timeout before accepting a new owner
   * @param _router The relevant router address
   */
  function getProposedRouterOwner(address _router) public view returns (address) {
    return routerInfo.proposedRouterOwners[_router];
  }

  /**
   * @notice Returns the currently proposed router owner timestamp
   * @dev All routers must wait for the delay timeout before accepting a new owner
   * @param _router The relevant router address
   */
  function getProposedRouterOwnerTimestamp(address _router) public view returns (uint256) {
    return routerInfo.proposedRouterTimestamp[_router];
  }

  /**
   * @notice Sets the designated recipient for a router
   * @dev Router should only be able to set this once otherwise if router key compromised,
   * no problem is solved since attacker could just update recipient
   * @param router Router address to set recipient
   * @param recipient Recipient Address to set to router
   */
  function setRouterRecipient(address router, address recipient) external {
    RouterPermissionsManagerLogic.setRouterRecipient(router, recipient, routerInfo);
  }

  /**
   * @notice Current owner or router may propose a new router owner
   * @param router Router address to set recipient
   * @param proposed Proposed owner Address to set to router
   */
  function proposeRouterOwner(address router, address proposed) external {
    RouterPermissionsManagerLogic.proposeRouterOwner(router, proposed, routerInfo);
  }

  /**
   * @notice New router owner must accept role, or previous if proposed is 0x0
   * @param router Router address to set recipient
   */
  function acceptProposedRouterOwner(address router) external {
    RouterPermissionsManagerLogic.acceptProposedRouterOwner(router, _delay, routerInfo);
  }

  // ============ Private methods =============

  /**
   * @notice Used to set router initial properties
   * @param router Router address to setup
   * @param owner Initial Owner of router
   * @param recipient Initial Recipient of router
   */
  function _setupRouter(
    address router,
    address owner,
    address recipient
  ) internal {
    RouterPermissionsManagerLogic.setupRouter(router, owner, recipient, routerInfo);
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param router Router address to remove
   */
  function _removeRouter(address router) internal {
    RouterPermissionsManagerLogic.removeRouter(router, routerInfo);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.11;

// ============ External Imports ============
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

library RelayerFeeMessage {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Enums ============

  // WARNING: do NOT re-write the numbers / order
  // of message types in an upgrade;
  // will cause in-flight messages to be mis-interpreted
  enum Types {
    Invalid, // 0
    ClaimFees // 1
  }

  // ============ Constants ============

  // before: 1 byte identifier + 20 bytes recipient + 32 bytes length + 32 bytes 1 transfer id = 85 bytes
  uint256 private constant MIN_CLAIM_LEN = 85;
  // before: 1 byte identifier + 20 bytes recipient = 21 bytes
  uint256 private constant LENGTH_ID_START = 21;
  uint8 private constant LENGTH_ID_LEN = 32;
  // before: 1 byte identifier
  uint256 private constant RECIPIENT_START = 1;
  // before: 1 byte identifier + 20 bytes recipient + 32 bytes length = 53 bytes
  uint256 private constant TRANSFER_IDS_START = 53;
  uint8 private constant TRANSFER_ID_LEN = 32;

  // ============ Modifiers ============

  /**
   * @notice Asserts a message is of type `_t`
   * @param _view The message
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Formatters ============

  /**
   * @notice Formats an claim fees message
   * @param _recipient The address of the relayer
   * @param _transferIds A group of transfers ids to claim for fee bumps
   * @return The formatted message
   */
  function formatClaimFees(address _recipient, bytes32[] calldata _transferIds) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(Types.ClaimFees), _recipient, _transferIds.length, _transferIds);
  }

  // ============ Getters ============

  /**
   * @notice Parse the recipient address of the fees
   * @param _view The message
   * @return The recipient address
   */
  function recipient(bytes29 _view) internal pure typeAssert(_view, Types.ClaimFees) returns (address) {
    // before = 1 byte identifier
    return _view.indexAddress(1);
  }

  /**
   * @notice Parse The group of transfers ids to claim for fee bumps
   * @param _view The message
   * @return The group of transfers ids to claim for fee bumps
   */
  function transferIds(bytes29 _view) internal pure typeAssert(_view, Types.ClaimFees) returns (bytes32[] memory) {
    uint256 length = _view.indexUint(LENGTH_ID_START, LENGTH_ID_LEN);

    bytes32[] memory ids = new bytes32[](length);
    for (uint256 i = 0; i < length; ) {
      ids[i] = _view.index(TRANSFER_IDS_START + i * TRANSFER_ID_LEN, TRANSFER_ID_LEN);

      unchecked {
        i++;
      }
    }
    return ids;
  }

  /**
   * @notice Checks that view is a valid message length
   * @param _view The bytes string
   * @return TRUE if message is valid
   */
  function isValidClaimFeesLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    // at least 1 transfer id where the excess is multiplier of transfer id length
    return _len >= MIN_CLAIM_LEN && (_len - TRANSFER_IDS_START) % TRANSFER_ID_LEN == 0;
  }

  /**
   * @notice Converts to a ClaimFees
   * @param _view The message
   * @return The newly typed message
   */
  function tryAsClaimFees(bytes29 _view) internal pure returns (bytes29) {
    if (isValidClaimFeesLength(_view)) {
      return _view.castTo(uint40(Types.ClaimFees));
    }
    return TypedMemView.nullView();
  }

  /**
   * @notice Asserts that the message is of type ClaimFees
   * @param _view The message
   * @return The message
   */
  function mustBeClaimFees(bytes29 _view) internal pure returns (bytes29) {
    return tryAsClaimFees(_view).assertValid();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {TypedMemView} from "../nomad-core/libs/TypedMemView.sol";

library LibCrossDomainProperty {
  // ============ Libraries ============

  using TypedMemView for bytes29;
  using TypedMemView for bytes;

  // ============ Enums ============

  /**
   * Contains information so the properties can be type-checked properly
   */
  enum Types {
    Invalid, // 0
    DomainAndSender // 1
  }

  // ============ Structs ============

  /**
   * Struct containing the domain and an address of the caller of a function on that
   * domain.
   */
  struct DomainAndSender {
    uint32 domain;
    address sender;
  }

  // ============ Constants ============

  uint256 private constant PROPERTY_LEN = 25; // 1 byte identifer + 4 bytes domain + 20 bytes address
  // default value is the TypedMemView null view
  bytes29 public constant EMPTY = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  bytes public constant EMPTY_BYTES = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

  // ============ Modifiers ============

  /**
   * @notice Asserts a property is of type `_t`
   * @param _view The stored property
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Internal Functions ============

  /**
   * @notice Checks that view is a valid property length
   * @param _view The bytes string
   * @return TRUE if length is valid
   */
  function isValidPropertyLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    return _len == PROPERTY_LEN;
  }

  /**
   * @notice Checks that the property is of the specified type
   * @param _type the type to check for
   * @param _property The property
   * @return True if the property is of the specified type
   */
  function isType(bytes29 _property, Types _type) internal pure returns (bool) {
    return propertyType(_property) == uint8(_type);
  }

  /**
   * @notice Checks that the property is of type DomainAndSender
   * @param _property The property
   * @return True if the property is of type DomainAndSender
   */
  function isDomainAndSender(bytes29 _property) internal pure returns (bool) {
    return isValidPropertyLength(_property) && isType(_property, Types.DomainAndSender);
  }

  /**
   * @notice Retrieves the identifier from property
   * @param _property The property
   * @return The property type
   */
  function propertyType(bytes29 _property) internal pure returns (uint8) {
    return uint8(_property.indexUint(0, 1));
  }

  /**
   * @notice Converts to a Property
   * @param _view The property
   * @return The newly typed property
   */
  function tryAsProperty(bytes29 _view) internal pure returns (bytes29) {
    if (isValidPropertyLength(_view)) {
      return _view.castTo(uint40(Types.DomainAndSender));
    }
    return TypedMemView.nullView();
  }

  /**
   * @notice Asserts that the property is of type DomainAndSender
   * @param _view The property
   * @return The property
   */
  function mustBeProperty(bytes29 _view) internal pure returns (bytes29) {
    return tryAsProperty(_view).assertValid();
  }

  /**
   * @notice Retrieves the sender from a property
   * @param _property The property
   * @return The sender address
   */
  function sender(bytes29 _property) internal pure typeAssert(_property, Types.DomainAndSender) returns (address) {
    // before = 1 byte id + 4 bytes domain = 5 bytes
    return _property.indexAddress(5);
  }

  /**
   * @notice Retrieves the domain from a property
   * @param _property The property
   * @return The sender address
   */
  function domain(bytes29 _property) internal pure typeAssert(_property, Types.DomainAndSender) returns (uint32) {
    // before = 1 byte identifier = 1 byte
    return uint32(_property.indexUint(1, 4));
  }

  /**
   * @notice Creates a serialized property from components
   * @param _domain The domain
   * @param _sender The sender
   * @return The formatted view
   */
  function formatDomainAndSender(uint32 _domain, address _sender) internal pure returns (bytes29) {
    return abi.encodePacked(Types.DomainAndSender, _domain, _sender).ref(0).castTo(uint40(Types.DomainAndSender));
  }

  /**
   * @notice Creates a serialized property from components
   * @param _domain The domain
   * @param _sender The sender
   * @return The formatted view
   */
  function formatDomainAndSenderBytes(uint32 _domain, address _sender) internal pure returns (bytes memory) {
    return abi.encodePacked(Types.DomainAndSender, _domain, _sender);
  }

  /**
   * @notice Creates a serialized property from components
   * @param _property The bytes representation of the property
   */
  function parseDomainAndSenderBytes(bytes memory _property) internal pure returns (bytes29) {
    return mustBeProperty(_property.ref(0));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

/**
 * @notice Contains RouterPermissionsManager related state
 * @param approvedRouters - Mapping of whitelisted router addresses
 * @param routerRecipients - Mapping of router withdraw recipient addresses.
 * If set, all liquidity is withdrawn only to this address. Must be set by routerOwner
 * (if configured) or the router itself
 * @param routerOwners - Mapping of router owners
 * If set, can update the routerRecipient
 * @param proposedRouterOwners - Mapping of proposed router owners
 * Must wait timeout to set the
 * @param proposedRouterTimestamp - Mapping of proposed router owners timestamps
 * When accepting a proposed owner, must wait for delay to elapse
 */
struct RouterPermissionsManagerInfo {
  mapping(address => bool) approvedRouters;
  mapping(address => address) routerRecipients;
  mapping(address => address) routerOwners;
  mapping(address => address) proposedRouterOwners;
  mapping(address => uint256) proposedRouterTimestamp;
}

library RouterPermissionsManagerLogic {
  // ========== Custom Errors ===========
  error RouterPermissionsManagerLogic__acceptProposedRouterOwner_notElapsed();
  error RouterPermissionsManagerLogic__setRouterRecipient_notNewRecipient();
  error RouterPermissionsManagerLogic__onlyRouterOwner_notRouterOwner();
  error RouterPermissionsManagerLogic__onlyProposedRouterOwner_notRouterOwner();
  error RouterPermissionsManagerLogic__onlyProposedRouterOwner_notProposedRouterOwner();
  error RouterPermissionsManagerLogic__removeRouter_routerEmpty();
  error RouterPermissionsManagerLogic__removeRouter_notAdded();
  error RouterPermissionsManagerLogic__setupRouter_routerEmpty();
  error RouterPermissionsManagerLogic__setupRouter_amountIsZero();
  error RouterPermissionsManagerLogic__proposeRouterOwner_notNewOwner();
  error RouterPermissionsManagerLogic__proposeRouterOwner_badRouter();

  /**
   * @notice Emitted when a new router is added
   * @param router - The address of the added router
   * @param caller - The account that called the function
   */
  event RouterAdded(address indexed router, address caller);

  /**
   * @notice Emitted when an existing router is removed
   * @param router - The address of the removed router
   * @param caller - The account that called the function
   */
  event RouterRemoved(address indexed router, address caller);

  /**
   * @notice Emitted when the recipient of router is updated
   * @param router - The address of the added router
   * @param prevRecipient  - The address of the previous recipient of the router
   * @param newRecipient  - The address of the new recipient of the router
   */
  event RouterRecipientSet(address indexed router, address indexed prevRecipient, address indexed newRecipient);

  /**
   * @notice Emitted when the owner of router is proposed
   * @param router - The address of the added router
   * @param prevProposed  - The address of the previous proposed
   * @param newProposed  - The address of the new proposed
   */
  event RouterOwnerProposed(address indexed router, address indexed prevProposed, address indexed newProposed);

  /**
   * @notice Emitted when the owner of router is accepted
   * @param router - The address of the added router
   * @param prevOwner  - The address of the previous owner of the router
   * @param newOwner  - The address of the new owner of the router
   */
  event RouterOwnerAccepted(address indexed router, address indexed prevOwner, address indexed newOwner);

  /**
   * @notice Asserts caller is the router owner (if set) or the router itself
   */
  function _onlyRouterOwner(address _router, address _owner) internal view {
    if (!((_owner == address(0) && msg.sender == _router) || _owner == msg.sender))
      revert RouterPermissionsManagerLogic__onlyRouterOwner_notRouterOwner();
  }

  /**
   * @notice Asserts caller is the proposed router. If proposed router is address(0), then asserts
   * the owner is calling the function (if set), or the router itself is calling the function
   */
  function _onlyProposedRouterOwner(
    address _router,
    address _owner,
    address _proposed
  ) internal view {
    if (_proposed == address(0)) {
      if (!((_owner == address(0) && msg.sender == _router) || _owner == msg.sender))
        revert RouterPermissionsManagerLogic__onlyProposedRouterOwner_notRouterOwner();
    } else {
      if (msg.sender != _proposed)
        revert RouterPermissionsManagerLogic__onlyProposedRouterOwner_notProposedRouterOwner();
    }
  }

  // ============ Public methods =============

  /**
   * @notice Sets the designated recipient for a router
   * @dev Router should only be able to set this once otherwise if router key compromised,
   * no problem is solved since attacker could just update recipient
   * @param router Router address to set recipient
   * @param recipient Recipient Address to set to router
   */
  function setRouterRecipient(
    address router,
    address recipient,
    RouterPermissionsManagerInfo storage routerInfo // mapping(address => address) storage routerOwners, // mapping(address => address) storage routerRecipients
  ) external {
    _onlyRouterOwner(router, routerInfo.routerOwners[router]);

    // Check recipient is changing
    address _prevRecipient = routerInfo.routerRecipients[router];
    if (_prevRecipient == recipient) revert RouterPermissionsManagerLogic__setRouterRecipient_notNewRecipient();

    // Set new recipient
    routerInfo.routerRecipients[router] = recipient;

    // Emit event
    emit RouterRecipientSet(router, _prevRecipient, recipient);
  }

  /**
   * @notice Current owner or router may propose a new router owner
   * @param router Router address to set recipient
   * @param proposed Proposed owner Address to set to router
   */
  function proposeRouterOwner(
    address router,
    address proposed,
    RouterPermissionsManagerInfo storage routerInfo
  ) external {
    _onlyRouterOwner(router, routerInfo.routerOwners[router]);

    // Check that proposed is different than current owner
    if (getRouterOwner(router, routerInfo.routerOwners) == proposed)
      revert RouterPermissionsManagerLogic__proposeRouterOwner_notNewOwner();

    // Check that proposed is different than current proposed
    address _currentProposed = routerInfo.proposedRouterOwners[router];
    if (_currentProposed == proposed) revert RouterPermissionsManagerLogic__proposeRouterOwner_badRouter();

    // Set proposed owner + timestamp
    routerInfo.proposedRouterOwners[router] = proposed;
    routerInfo.proposedRouterTimestamp[router] = block.timestamp;

    // Emit event
    emit RouterOwnerProposed(router, _currentProposed, proposed);
  }

  /**
   * @notice New router owner must accept role, or previous if proposed is 0x0
   * @param router Router address to set recipient
   */
  function acceptProposedRouterOwner(
    address router,
    uint256 _delay,
    RouterPermissionsManagerInfo storage routerInfo
  ) external {
    _onlyProposedRouterOwner(router, routerInfo.routerOwners[router], routerInfo.proposedRouterOwners[router]);

    address owner = getRouterOwner(router, routerInfo.routerOwners);

    // Check timestamp has passed
    if (block.timestamp - routerInfo.proposedRouterTimestamp[router] <= _delay)
      revert RouterPermissionsManagerLogic__acceptProposedRouterOwner_notElapsed();

    // Get current owner + proposed
    address _proposed = routerInfo.proposedRouterOwners[router];

    // Update the current owner
    routerInfo.routerOwners[router] = _proposed;

    // Reset proposal + timestamp
    if (_proposed != address(0)) {
      // delete proposedRouterOwners[router];
      routerInfo.proposedRouterOwners[router] = address(0);
    }
    routerInfo.proposedRouterTimestamp[router] = 0;

    // Emit event
    emit RouterOwnerAccepted(router, owner, _proposed);
  }

  /**
   * @notice Used to set router initial properties
   * @param router Router address to setup
   * @param owner Initial Owner of router
   * @param recipient Initial Recipient of router
   */
  function setupRouter(
    address router,
    address owner,
    address recipient,
    RouterPermissionsManagerInfo storage routerInfo
  ) internal {
    // Sanity check: not empty
    if (router == address(0)) revert RouterPermissionsManagerLogic__setupRouter_routerEmpty();

    // Sanity check: needs approval
    if (routerInfo.approvedRouters[router]) revert RouterPermissionsManagerLogic__setupRouter_amountIsZero();

    // Approve router
    routerInfo.approvedRouters[router] = true;

    // Emit event
    emit RouterAdded(router, msg.sender);

    // Update routerOwner (zero address possible)
    if (owner != address(0)) {
      routerInfo.routerOwners[router] = owner;
      emit RouterOwnerAccepted(router, address(0), owner);
    }

    // Update router recipient
    if (recipient != address(0)) {
      routerInfo.routerRecipients[router] = recipient;
      emit RouterRecipientSet(router, address(0), recipient);
    }
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param router Router address to remove
   */
  function removeRouter(address router, RouterPermissionsManagerInfo storage routerInfo) external {
    // Sanity check: not empty
    if (router == address(0)) revert RouterPermissionsManagerLogic__removeRouter_routerEmpty();

    // Sanity check: needs removal
    if (!routerInfo.approvedRouters[router]) revert RouterPermissionsManagerLogic__removeRouter_notAdded();

    // Update mapping
    routerInfo.approvedRouters[router] = false;

    // Emit event
    emit RouterRemoved(router, msg.sender);

    // Remove router owner
    address _owner = routerInfo.routerOwners[router];
    if (_owner != address(0)) {
      emit RouterOwnerAccepted(router, _owner, address(0));
      // delete routerOwners[router];
      routerInfo.routerOwners[router] = address(0);
    }

    // Remove router recipient
    address _recipient = routerInfo.routerRecipients[router];
    if (_recipient != address(0)) {
      emit RouterRecipientSet(router, _recipient, address(0));
      // delete routerRecipients[router];
      routerInfo.routerRecipients[router] = address(0);
    }
  }

  /**
   * @notice Returns the router owner if it is set, or the router itself if not
   * @dev Router owners have the ability to propose new owners and set recipients
   * @param _router The relevant router address
   * @param _routerOwners The mapping of owners for routers
   */
  function getRouterOwner(address _router, mapping(address => address) storage _routerOwners)
    internal
    view
    returns (address)
  {
    address _owner = _routerOwners[_router];
    return _owner == address(0) ? _router : _owner;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IWrapped} from "../../interfaces/IWrapped.sol";
import {IStableSwap} from "../../interfaces/IStableSwap.sol";
import {ConnextMessage} from "../../nomad-xapps/contracts/connext/ConnextMessage.sol";
import {ITokenRegistry} from "../../nomad-xapps/interfaces/bridge/ITokenRegistry.sol";

import {SafeERC20Upgradeable, IERC20Upgradeable, AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library AssetLogic {
  error AssetLogic__handleIncomingAsset_notAmount();
  error AssetLogic__handleIncomingAsset_ethWithErcTransfer();
  error AssetLogic__transferAssetFromContract_notNative();

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev If using the native asset, will automatically wrap
   * @param _assetId - The address to transfer
   * @param _assetAmount - The specified amount to transfer. May not be the
   * actual amount transferred (i.e. fee on transfer tokens)
   * @param _fee - The fee amount in native asset included as part of the transaction that
   * should not be considered for the transfer amount.
   * @param _wrapper - The address of the wrapper for the native asset on this domain
   * @return The assetId of the transferred asset
   * @return The amount of the asset that was seen by the contract (may not be the specifiedAmount
   * if the token is a fee-on-transfer token)
   */
  function handleIncomingAsset(
    address _assetId,
    uint256 _assetAmount,
    uint256 _fee,
    IWrapped _wrapper
  ) internal returns (address, uint256) {
    uint256 trueAmount = _assetAmount;

    if (_assetId == address(0)) {
      if (msg.value != _assetAmount + _fee) revert AssetLogic__handleIncomingAsset_notAmount();

      // When transferring native asset to the contract, always make sure that the
      // asset is properly wrapped
      wrapNativeAsset(_assetAmount, _wrapper);
      _assetId = address(_wrapper);
    } else {
      if (msg.value != _fee) revert AssetLogic__handleIncomingAsset_ethWithErcTransfer();

      // Transfer asset to contract
      trueAmount = transferAssetToContract(_assetId, _assetAmount);
    }

    return (_assetId, trueAmount);
  }

  /**
   * @notice Wrap the native asset
   * @param _amount - The specified amount to wrap
   * @param _wrapper - The address of the wrapper for the native asset on this domain
   */
  function wrapNativeAsset(uint256 _amount, IWrapped _wrapper) internal {
    _wrapper.deposit{value: _amount}();
  }

  /**
   * @notice Transfer asset funds from msg.sender to the Connext contract.
   * @param _assetId - The address to transfer
   * @param _amount - The specified amount to transfer
   * @return The amount of the asset that was seen by the contract
   */
  function transferAssetToContract(address _assetId, uint256 _amount) internal returns (uint256) {
    // Validate correct amounts are transferred
    uint256 starting = IERC20Upgradeable(_assetId).balanceOf(address(this));

    SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_assetId), msg.sender, address(this), _amount);
    // Calculate the *actual* amount that was sent here
    return IERC20Upgradeable(_assetId).balanceOf(address(this)) - starting;
  }

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev If using the native asset, will automatically unwrap
   * @param _assetId - The address to transfer
   * @param _to - The account that will receive the withdrawn funds
   * @param _amount - The amount to withdraw from contract
   * @param _wrapper - The address of the wrapper for the native asset on this domain
   */
  function transferAssetFromContract(
    address _assetId,
    address _to,
    uint256 _amount,
    IWrapped _wrapper
  ) internal {
    // No native assets should ever be stored on this contract
    if (_assetId == address(0)) revert AssetLogic__transferAssetFromContract_notNative();

    if (_assetId == address(_wrapper)) {
      // If dealing with wrapped assets, make sure they are properly unwrapped
      // before sending from contract
      _wrapper.withdraw(_amount);
      AddressUpgradeable.sendValue(payable(_to), _amount);
    } else {
      // Transfer ERC20 asset
      SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_assetId), _to, _amount);
    }
  }

  /**
   * @notice Swaps an adopted asset to the local (representation or canonical) nomad asset
   * @dev Will not swap if the asset passed in is the local asset
   * @param _canonical - The canonical token
   * @param _pool - The StableSwap pool
   * @param _tokenRegistry - The local nomad token registry
   * @param _asset - The address of the adopted asset to swap into the local asset
   * @param _amount - The amount of the adopted asset to swap
   * @return The amount of local asset received from swap
   * @return The address of asset received post-swap
   */
  function swapToLocalAssetIfNeeded(
    ConnextMessage.TokenId memory _canonical,
    IStableSwap _pool,
    ITokenRegistry _tokenRegistry,
    address _asset,
    uint256 _amount
  ) internal returns (uint256, address) {
    // Check to see if the asset must be swapped because it is not the local asset
    if (_canonical.id == bytes32(0)) {
      // This is *not* the adopted asset, meaning it must be the local asset
      return (_amount, _asset);
    }

    // Get the local token for this domain (may return canonical or representation)
    address local = _tokenRegistry.getLocalAddress(_canonical.domain, _canonical.id);

    // if theres no amount, no need to swap
    if (_amount == 0) {
      return (_amount, local);
    }

    // Check the case where the adopted asset *is* the local asset
    if (local == _asset) {
      // No need to swap
      return (_amount, _asset);
    }

    // Approve pool
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_asset), address(_pool), _amount);

    // Swap the asset to the proper local asset
    return (_pool.swapExact(_amount, _asset, local), local);
  }

  /**
   * @notice Swaps a local nomad asset for the adopted asset using the stored stable swap
   * @dev Will not swap if the asset passed in is the adopted asset
   * @param _canonicalToAdopted - Mapping of adopted to canonical on this domain
   * @param _adoptedToLocalPools - Mapping holding the AMMs for swapping in and out of local assets
   * @param _tokenRegistry - The local nomad token registry
   * @param _asset - The address of the local asset to swap into the adopted asset
   * @param _amount - The amount of the local asset to swap
   * @return The amount of adopted asset received from swap
   * @return The address of asset received post-swap
   */
  function swapFromLocalAssetIfNeeded(
    mapping(bytes32 => address) storage _canonicalToAdopted,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools,
    ITokenRegistry _tokenRegistry,
    address _asset,
    uint256 _amount
  ) internal returns (uint256, address) {
    // Get the token id
    (, bytes32 id) = _tokenRegistry.getTokenId(_asset);

    // If the adopted asset is the local asset, no need to swap
    address adopted = _canonicalToAdopted[id];
    if (adopted == _asset) {
      return (_amount, _asset);
    }

    // Approve pool
    IStableSwap pool = _adoptedToLocalPools[id];
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_asset), address(pool), _amount);

    // Otherwise, swap to adopted asset
    return (pool.swapExact(_amount, _asset, adopted), adopted);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnerPausableUpgradeable} from "./lib/StableSwap/OwnerPausableUpgradeable.sol";
import {AmplificationUtils, SwapUtils} from "./lib/StableSwap/AmplificationUtils.sol";
import {LPToken} from "./lib/StableSwap/LPToken.sol";
import {IStableSwap} from "./interfaces/IStableSwap.sol";

/**
 * @title Swap - A StableSwap implementation in solidity.
 * @notice This contract is responsible for custody of closely pegged assets (eg. group of stablecoins)
 * and automatic market making system. Users become an LP (Liquidity Provider) by depositing their tokens
 * in desired ratios for an exchange of the pool token that represents their share of the pool.
 * Users can burn pool tokens and withdraw their share of token(s).
 *
 * Each time a swap between the pooled tokens happens, a set fee incurs which effectively gets
 * distributed to the LPs.
 *
 * In case of emergencies, admin can pause additional deposits, swaps, or single-asset withdraws - which
 * stops the ratio of the tokens in the pool from changing.
 * Users can always withdraw their tokens via multi-asset withdraws.
 *
 * @dev Most of the logic is stored as a library `SwapUtils` for the sake of reducing contract's
 * deployment size.
 */
contract StableSwap is IStableSwap, OwnerPausableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20 for IERC20;
  using SwapUtils for SwapUtils.Swap;
  using AmplificationUtils for SwapUtils.Swap;

  // Struct storing data responsible for automatic market maker functionalities. In order to
  // access this data, this contract uses SwapUtils library. For more details, see SwapUtils.sol
  SwapUtils.Swap public swapStorage;

  // Maps token address to an index in the pool. Used to prevent duplicate tokens in the pool.
  // getTokenIndex function also relies on this mapping to retrieve token index.
  mapping(address => uint8) private tokenIndexes;

  /**
   * @notice Initializes this Swap contract with the given parameters.
   * This will also clone a LPToken contract that represents users'
   * LP positions. The owner of LPToken will be this contract - which means
   * only this contract is allowed to mint/burn tokens.
   *
   * @param _pooledTokens an array of ERC20s this pool will accept
   * @param decimals the decimals to use for each pooled token,
   * eg 8 for WBTC. Cannot be larger than POOL_PRECISION_DECIMALS
   * @param lpTokenName the long-form name of the token to be deployed
   * @param lpTokenSymbol the short symbol for the token to be deployed
   * @param _a the amplification coefficient * n * (n - 1). See the
   * StableSwap paper for details
   * @param _fee default swap fee to be initialized with
   * @param _adminFee default adminFee to be initialized with
   * @param lpTokenTargetAddress the address of an existing LPToken contract to use as a target
   */
  function initialize(
    IERC20[] memory _pooledTokens,
    uint8[] memory decimals,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    uint256 _a,
    uint256 _fee,
    uint256 _adminFee,
    address lpTokenTargetAddress
  ) public override initializer {
    __OwnerPausable_init();
    __ReentrancyGuard_init();

    // Check _pooledTokens and precisions parameter
    require(_pooledTokens.length > 1, "_pooledTokens.length <= 1");
    require(_pooledTokens.length <= 32, "_pooledTokens.length > 32");
    require(_pooledTokens.length == decimals.length, "_pooledTokens decimals mismatch");

    uint256[] memory precisionMultipliers = new uint256[](decimals.length);

    for (uint8 i = 0; i < _pooledTokens.length; i++) {
      if (i > 0) {
        // Check if index is already used. Check if 0th element is a duplicate.
        require(
          tokenIndexes[address(_pooledTokens[i])] == 0 && _pooledTokens[0] != _pooledTokens[i],
          "Duplicate tokens"
        );
      }
      require(address(_pooledTokens[i]) != address(0), "The 0 address isn't an ERC-20");
      require(decimals[i] <= SwapUtils.POOL_PRECISION_DECIMALS, "Token decimals exceeds max");
      precisionMultipliers[i] = 10**uint256(SwapUtils.POOL_PRECISION_DECIMALS - decimals[i]);
      tokenIndexes[address(_pooledTokens[i])] = i;
    }

    // Check _a, _fee, _adminFee, _withdrawFee parameters
    require(_a < AmplificationUtils.MAX_A, "_a exceeds maximum");
    require(_fee < SwapUtils.MAX_SWAP_FEE, "_fee exceeds maximum");
    require(_adminFee < SwapUtils.MAX_ADMIN_FEE, "_adminFee exceeds maximum");

    // Initialize a LPToken contract
    LPToken lpToken = LPToken(Clones.clone(lpTokenTargetAddress));
    require(lpToken.initialize(lpTokenName, lpTokenSymbol), "could not init lpToken clone");

    // Initialize swapStorage struct
    swapStorage.lpToken = lpToken;
    swapStorage.pooledTokens = _pooledTokens;
    swapStorage.tokenPrecisionMultipliers = precisionMultipliers;
    swapStorage.balances = new uint256[](_pooledTokens.length);
    swapStorage.initialA = _a * AmplificationUtils.A_PRECISION;
    swapStorage.futureA = _a * AmplificationUtils.A_PRECISION;
    // swapStorage.initialATime = 0;
    // swapStorage.futureATime = 0;
    swapStorage.swapFee = _fee;
    swapStorage.adminFee = _adminFee;
  }

  /*** MODIFIERS ***/

  /**
   * @notice Modifier to check deadline against current timestamp
   * @param deadline latest timestamp to accept this transaction
   */
  modifier deadlineCheck(uint256 deadline) {
    require(block.timestamp <= deadline, "Deadline not met");
    _;
  }

  /*** VIEW FUNCTIONS ***/

  /**
   * @notice Return A, the amplification coefficient * n * (n - 1)
   * @dev See the StableSwap paper for details
   * @return A parameter
   */
  function getA() external view override returns (uint256) {
    return swapStorage.getA();
  }

  /**
   * @notice Return A in its raw precision form
   * @dev See the StableSwap paper for details
   * @return A parameter in its raw precision form
   */
  function getAPrecise() external view returns (uint256) {
    return swapStorage.getAPrecise();
  }

  /**
   * @notice Return address of the pooled token at given index. Reverts if tokenIndex is out of range.
   * @param index the index of the token
   * @return address of the token at given index
   */
  function getToken(uint8 index) public view override returns (IERC20) {
    require(index < swapStorage.pooledTokens.length, "Out of range");
    return swapStorage.pooledTokens[index];
  }

  /**
   * @notice Return the index of the given token address. Reverts if no matching
   * token is found.
   * @param tokenAddress address of the token
   * @return the index of the given token address
   */
  function getTokenIndex(address tokenAddress) public view override returns (uint8) {
    uint8 index = tokenIndexes[tokenAddress];
    require(address(getToken(index)) == tokenAddress, "Token does not exist");
    return index;
  }

  /**
   * @notice Return current balance of the pooled token at given index
   * @param index the index of the token
   * @return current balance of the pooled token at given index with token's native precision
   */
  function getTokenBalance(uint8 index) external view override returns (uint256) {
    require(index < swapStorage.pooledTokens.length, "Index out of range");
    return swapStorage.balances[index];
  }

  /**
   * @notice Get the virtual price, to help calculate profit
   * @return the virtual price, scaled to the POOL_PRECISION_DECIMALS
   */
  function getVirtualPrice() external view override returns (uint256) {
    return swapStorage.getVirtualPrice();
  }

  /**
   * @notice Calculate amount of tokens you receive on swap
   * @param tokenIndexFrom the token the user wants to sell
   * @param tokenIndexTo the token the user wants to buy
   * @param dx the amount of tokens the user wants to sell. If the token charges
   * a fee on transfers, use the amount that gets transferred after the fee.
   * @return amount of tokens the user will receive
   */
  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view override returns (uint256) {
    return swapStorage.calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
  }

  /**
   * @notice A simple method to calculate prices from deposits or
   * withdrawals, excluding fees but including slippage. This is
   * helpful as an input into the various "min" parameters on calls
   * to fight front-running
   *
   * @dev This shouldn't be used outside frontends for user estimates.
   *
   * @param amounts an array of token amounts to deposit or withdrawal,
   * corresponding to pooledTokens. The amount should be in each
   * pooled token's native precision. If a token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @param deposit whether this is a deposit or a withdrawal
   * @return token amount the user will receive
   */
  function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view override returns (uint256) {
    return swapStorage.calculateTokenAmount(amounts, deposit);
  }

  /**
   * @notice A simple method to calculate amount of each underlying
   * tokens that is returned upon burning given amount of LP tokens
   * @param amount the amount of LP tokens that would be burned on withdrawal
   * @return array of token balances that the user will receive
   */
  function calculateRemoveLiquidity(uint256 amount) external view override returns (uint256[] memory) {
    return swapStorage.calculateRemoveLiquidity(amount);
  }

  /**
   * @notice Calculate the amount of underlying token available to withdraw
   * when withdrawing via only single token
   * @param tokenAmount the amount of LP token to burn
   * @param tokenIndex index of which token will be withdrawn
   * @return availableTokenAmount calculated amount of underlying token
   * available to withdraw
   */
  function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
    external
    view
    override
    returns (uint256 availableTokenAmount)
  {
    return swapStorage.calculateWithdrawOneToken(tokenAmount, tokenIndex);
  }

  /**
   * @notice This function reads the accumulated amount of admin fees of the token with given index
   * @param index Index of the pooled token
   * @return admin's token balance in the token's precision
   */
  function getAdminBalance(uint256 index) external view returns (uint256) {
    return swapStorage.getAdminBalance(index);
  }

  /*** STATE MODIFYING FUNCTIONS ***/

  /**
   * @notice Swap two tokens using this pool
   * @param tokenIndexFrom the token the user wants to swap from
   * @param tokenIndexTo the token the user wants to swap to
   * @param dx the amount of tokens the user wants to swap from
   * @param minDy the min amount the user would like to receive, or revert.
   * @param deadline latest timestamp to accept this transaction
   */
  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external override nonReentrant whenNotPaused deadlineCheck(deadline) returns (uint256) {
    return swapStorage.swap(tokenIndexFrom, tokenIndexTo, dx, minDy);
  }

  /**
   * @notice Swap two tokens using this pool
   * @param assetIn the token the user wants to swap from
   * @param assetOut the token the user wants to swap to
   * @param amountIn the amount of tokens the user wants to swap from
   */
  function swapExact(
    uint256 amountIn,
    address assetIn,
    address assetOut
  ) external payable override nonReentrant whenNotPaused returns (uint256) {
    uint8 tokenIndexFrom = getTokenIndex(assetIn);
    uint8 tokenIndexTo = getTokenIndex(assetOut);
    return swapStorage.swap(tokenIndexFrom, tokenIndexTo, amountIn, 0);
  }

  /**
   * @notice Add liquidity to the pool with the given amounts of tokens
   * @param amounts the amounts of each token to add, in their native precision
   * @param minToMint the minimum LP tokens adding this amount of liquidity
   * should mint, otherwise revert. Handy for front-running mitigation
   * @param deadline latest timestamp to accept this transaction
   * @return amount of LP token user minted and received
   */
  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external override nonReentrant whenNotPaused deadlineCheck(deadline) returns (uint256) {
    return swapStorage.addLiquidity(amounts, minToMint);
  }

  /**
   * @notice Burn LP tokens to remove liquidity from the pool. Withdraw fee that decays linearly
   * over period of 4 weeks since last deposit will apply.
   * @dev Liquidity can always be removed, even when the pool is paused.
   * @param amount the amount of LP tokens to burn
   * @param minAmounts the minimum amounts of each token in the pool
   *        acceptable for this burn. Useful as a front-running mitigation
   * @param deadline latest timestamp to accept this transaction
   * @return amounts of tokens user received
   */
  function removeLiquidity(
    uint256 amount,
    uint256[] calldata minAmounts,
    uint256 deadline
  ) external override nonReentrant deadlineCheck(deadline) returns (uint256[] memory) {
    return swapStorage.removeLiquidity(amount, minAmounts);
  }

  /**
   * @notice Remove liquidity from the pool all in one token. Withdraw fee that decays linearly
   * over period of 4 weeks since last deposit will apply.
   * @param tokenAmount the amount of the token you want to receive
   * @param tokenIndex the index of the token you want to receive
   * @param minAmount the minimum amount to withdraw, otherwise revert
   * @param deadline latest timestamp to accept this transaction
   * @return amount of chosen token user received
   */
  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external override nonReentrant whenNotPaused deadlineCheck(deadline) returns (uint256) {
    return swapStorage.removeLiquidityOneToken(tokenAmount, tokenIndex, minAmount);
  }

  /**
   * @notice Remove liquidity from the pool, weighted differently than the
   * pool's current balances. Withdraw fee that decays linearly
   * over period of 4 weeks since last deposit will apply.
   * @param amounts how much of each token to withdraw
   * @param maxBurnAmount the max LP token provider is willing to pay to
   * remove liquidity. Useful as a front-running mitigation.
   * @param deadline latest timestamp to accept this transaction
   * @return amount of LP tokens burned
   */
  function removeLiquidityImbalance(
    uint256[] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external override nonReentrant whenNotPaused deadlineCheck(deadline) returns (uint256) {
    return swapStorage.removeLiquidityImbalance(amounts, maxBurnAmount);
  }

  /*** ADMIN FUNCTIONS ***/

  /**
   * @notice Withdraw all admin fees to the contract owner
   */
  function withdrawAdminFees() external onlyOwner {
    swapStorage.withdrawAdminFees(owner());
  }

  /**
   * @notice Update the admin fee. Admin fee takes portion of the swap fee.
   * @param newAdminFee new admin fee to be applied on future transactions
   */
  function setAdminFee(uint256 newAdminFee) external onlyOwner {
    swapStorage.setAdminFee(newAdminFee);
  }

  /**
   * @notice Update the swap fee to be applied on swaps
   * @param newSwapFee new swap fee to be applied on future transactions
   */
  function setSwapFee(uint256 newSwapFee) external onlyOwner {
    swapStorage.setSwapFee(newSwapFee);
  }

  /**
   * @notice Start ramping up or down A parameter towards given futureA and futureTime
   * Checks if the change is too rapid, and commits the new A value only when it falls under
   * the limit range.
   * @param futureA the new A to ramp towards
   * @param futureTime timestamp when the new A should be reached
   */
  function rampA(uint256 futureA, uint256 futureTime) external onlyOwner {
    swapStorage.rampA(futureA, futureTime);
  }

  /**
   * @notice Stop ramping A immediately. Reverts if ramp A is already stopped.
   */
  function stopRampA() external onlyOwner {
    swapStorage.stopRampA();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title OwnerPausable
 * @notice An ownable contract allows the owner to pause and unpause the
 * contract without a delay.
 * @dev Only methods using the provided modifiers will be paused.
 */
abstract contract OwnerPausableUpgradeable is OwnableUpgradeable, PausableUpgradeable {
  function __OwnerPausable_init() internal onlyInitializing {
    __Context_init_unchained();
    __Ownable_init_unchained();
    __Pausable_init_unchained();
  }

  /**
   * @notice Pause the contract. Revert if already paused.
   */
  function pause() external onlyOwner {
    PausableUpgradeable._pause();
  }

  /**
   * @notice Unpause the contract. Revert if already unpaused.
   */
  function unpause() external onlyOwner {
    PausableUpgradeable._unpause();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SwapUtils} from "./SwapUtils.sol";

/**
 * @title AmplificationUtils library
 * @notice A library to calculate and ramp the A parameter of a given `SwapUtils.Swap` struct.
 * This library assumes the struct is fully validated.
 */
library AmplificationUtils {
  using SafeMath for uint256;

  event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
  event StopRampA(uint256 currentA, uint256 time);

  // Constant values used in ramping A calculations
  uint256 public constant A_PRECISION = 100;
  uint256 public constant MAX_A = 10**6;
  uint256 private constant MAX_A_CHANGE = 2;
  uint256 private constant MIN_RAMP_TIME = 14 days;

  /**
   * @notice Return A, the amplification coefficient * n * (n - 1)
   * @dev See the StableSwap paper for details
   * @param self Swap struct to read from
   * @return A parameter
   */
  function getA(SwapUtils.Swap storage self) external view returns (uint256) {
    return _getAPrecise(self).div(A_PRECISION);
  }

  /**
   * @notice Return A in its raw precision
   * @dev See the StableSwap paper for details
   * @param self Swap struct to read from
   * @return A parameter in its raw precision form
   */
  function getAPrecise(SwapUtils.Swap storage self) external view returns (uint256) {
    return _getAPrecise(self);
  }

  /**
   * @notice Return A in its raw precision
   * @dev See the StableSwap paper for details
   * @param self Swap struct to read from
   * @return A parameter in its raw precision form
   */
  function _getAPrecise(SwapUtils.Swap storage self) internal view returns (uint256) {
    uint256 t1 = self.futureATime; // time when ramp is finished
    uint256 a1 = self.futureA; // final A value when ramp is finished

    if (block.timestamp < t1) {
      uint256 t0 = self.initialATime; // time when ramp is started
      uint256 a0 = self.initialA; // initial A value when ramp is started
      if (a1 > a0) {
        // a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0)
        return a0.add(a1.sub(a0).mul(block.timestamp.sub(t0)).div(t1.sub(t0)));
      } else {
        // a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0)
        return a0.sub(a0.sub(a1).mul(block.timestamp.sub(t0)).div(t1.sub(t0)));
      }
    } else {
      return a1;
    }
  }

  /**
   * @notice Start ramping up or down A parameter towards given futureA_ and futureTime_
   * Checks if the change is too rapid, and commits the new A value only when it falls under
   * the limit range.
   * @param self Swap struct to update
   * @param futureA_ the new A to ramp towards
   * @param futureTime_ timestamp when the new A should be reached
   */
  function rampA(
    SwapUtils.Swap storage self,
    uint256 futureA_,
    uint256 futureTime_
  ) external {
    require(block.timestamp >= self.initialATime.add(1 days), "Wait 1 day before starting ramp");
    require(futureTime_ >= block.timestamp.add(MIN_RAMP_TIME), "Insufficient ramp time");
    require(futureA_ > 0 && futureA_ < MAX_A, "futureA_ must be > 0 and < MAX_A");

    uint256 initialAPrecise = _getAPrecise(self);
    uint256 futureAPrecise = futureA_.mul(A_PRECISION);

    if (futureAPrecise < initialAPrecise) {
      require(futureAPrecise.mul(MAX_A_CHANGE) >= initialAPrecise, "futureA_ is too small");
    } else {
      require(futureAPrecise <= initialAPrecise.mul(MAX_A_CHANGE), "futureA_ is too large");
    }

    self.initialA = initialAPrecise;
    self.futureA = futureAPrecise;
    self.initialATime = block.timestamp;
    self.futureATime = futureTime_;

    emit RampA(initialAPrecise, futureAPrecise, block.timestamp, futureTime_);
  }

  /**
   * @notice Stops ramping A immediately. Once this function is called, rampA()
   * cannot be called for another 24 hours
   * @param self Swap struct to update
   */
  function stopRampA(SwapUtils.Swap storage self) external {
    require(self.futureATime > block.timestamp, "Ramp is already stopped");

    uint256 currentA = _getAPrecise(self);
    self.initialA = currentA;
    self.futureA = currentA;
    self.initialATime = block.timestamp;
    self.futureATime = block.timestamp;

    emit StopRampA(currentA, block.timestamp);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {ERC20BurnableUpgradeable, ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @title Liquidity Provider Token
 * @notice This token is an ERC20 detailed token with added capability to be minted by the owner.
 * It is used to represent user's shares when providing liquidity to swap contracts.
 * @dev Only Swap contracts should initialize and own LPToken contracts.
 */
contract LPToken is ERC20BurnableUpgradeable, OwnableUpgradeable {
  using SafeMathUpgradeable for uint256;

  /**
   * @notice Initializes this LPToken contract with the given name and symbol
   * @dev The caller of this function will become the owner. A Swap contract should call this
   * in its initializer function.
   * @param name name of this token
   * @param symbol symbol of this token
   */
  function initialize(string memory name, string memory symbol) external initializer returns (bool) {
    __Context_init_unchained();
    __ERC20_init_unchained(name, symbol);
    __Ownable_init_unchained();
    return true;
  }

  /**
   * @notice Mints the given amount of LPToken to the recipient.
   * @dev only owner can call this mint function
   * @param recipient address of account to receive the tokens
   * @param amount amount of tokens to mint
   */
  function mint(address recipient, uint256 amount) external onlyOwner {
    require(amount != 0, "LPToken: cannot mint 0");
    _mint(recipient, amount);
  }

  /**
   * @dev Overrides ERC20._beforeTokenTransfer() which get called on every transfers including
   * minting and burning. This ensures that Swap.updateUserWithdrawFees are called everytime.
   * This assumes the owner is set to a Swap contract's address.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable) {
    super._beforeTokenTransfer(from, to, amount);
    require(to != address(this), "LPToken: cannot send to itself");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AmplificationUtils} from "./AmplificationUtils.sol";
import {LPToken} from "./LPToken.sol";
import {MathUtils} from "./MathUtils.sol";

/**
 * @title SwapUtils library
 * @notice A library to be used within Swap.sol. Contains functions responsible for custody and AMM functionalities.
 * @dev Contracts relying on this library must initialize SwapUtils.Swap struct then use this library
 * for SwapUtils.Swap struct. Note that this library contains both functions called by users and admins.
 * Admin functions should be protected within contracts using this library.
 */
library SwapUtils {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using MathUtils for uint256;

  /*** EVENTS ***/

  event TokenSwap(address indexed buyer, uint256 tokensSold, uint256 tokensBought, uint128 soldId, uint128 boughtId);
  event AddLiquidity(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256 lpTokenSupply);
  event RemoveLiquidityOne(
    address indexed provider,
    uint256 lpTokenAmount,
    uint256 lpTokenSupply,
    uint256 boughtId,
    uint256 tokensBought
  );
  event RemoveLiquidityImbalance(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event NewAdminFee(uint256 newAdminFee);
  event NewSwapFee(uint256 newSwapFee);

  struct Swap {
    // variables around the ramp management of A,
    // the amplification coefficient * n * (n - 1)
    // see https://www.curve.fi/stableswap-paper.pdf for details
    uint256 initialA;
    uint256 futureA;
    uint256 initialATime;
    uint256 futureATime;
    // fee calculation
    uint256 swapFee;
    uint256 adminFee;
    LPToken lpToken;
    // contract references for all tokens being pooled
    IERC20[] pooledTokens;
    // multipliers for each pooled token's precision to get to POOL_PRECISION_DECIMALS
    // for example, TBTC has 18 decimals, so the multiplier should be 1. WBTC
    // has 8, so the multiplier should be 10 ** 18 / 10 ** 8 => 10 ** 10
    uint256[] tokenPrecisionMultipliers;
    // the pool balance of each token, in the token's precision
    // the contract's actual token balance might differ
    uint256[] balances;
  }

  // Struct storing variables used in calculations in the
  // calculateWithdrawOneTokenDY function to avoid stack too deep errors
  struct CalculateWithdrawOneTokenDYInfo {
    uint256 d0;
    uint256 d1;
    uint256 newY;
    uint256 feePerToken;
    uint256 preciseA;
  }

  // Struct storing variables used in calculations in the
  // {add,remove}Liquidity functions to avoid stack too deep errors
  struct ManageLiquidityInfo {
    uint256 d0;
    uint256 d1;
    uint256 d2;
    uint256 preciseA;
    LPToken lpToken;
    uint256 totalSupply;
    uint256[] balances;
    uint256[] multipliers;
  }

  // the precision all pools tokens will be converted to
  uint8 public constant POOL_PRECISION_DECIMALS = 18;

  // the denominator used to calculate admin and LP fees. For example, an
  // LP fee might be something like tradeAmount.mul(fee).div(FEE_DENOMINATOR)
  uint256 private constant FEE_DENOMINATOR = 10**10;

  // Max swap fee is 1% or 100bps of each swap
  uint256 public constant MAX_SWAP_FEE = 10**8;

  // Max adminFee is 100% of the swapFee
  // adminFee does not add additional fee on top of swapFee
  // Instead it takes a certain % of the swapFee. Therefore it has no impact on the
  // users but only on the earnings of LPs
  uint256 public constant MAX_ADMIN_FEE = 10**10;

  // Constant value used as max loop limit
  uint256 private constant MAX_LOOP_LIMIT = 256;

  /*** VIEW & PURE FUNCTIONS ***/

  function _getAPrecise(Swap storage self) internal view returns (uint256) {
    return AmplificationUtils._getAPrecise(self);
  }

  /**
   * @notice Calculate the dy, the amount of selected token that user receives and
   * the fee of withdrawing in one token
   * @param tokenAmount the amount to withdraw in the pool's precision
   * @param tokenIndex which token will be withdrawn
   * @param self Swap struct to read from
   * @return the amount of token user will receive
   */
  function calculateWithdrawOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex
  ) external view returns (uint256) {
    (uint256 availableTokenAmount, ) = _calculateWithdrawOneToken(
      self,
      tokenAmount,
      tokenIndex,
      self.lpToken.totalSupply()
    );
    return availableTokenAmount;
  }

  function _calculateWithdrawOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 totalSupply
  ) internal view returns (uint256, uint256) {
    uint256 dy;
    uint256 newY;
    uint256 currentY;

    (dy, newY, currentY) = calculateWithdrawOneTokenDY(self, tokenIndex, tokenAmount, totalSupply);

    // dy_0 (without fees)
    // dy, dy_0 - dy

    uint256 dySwapFee = currentY.sub(newY).div(self.tokenPrecisionMultipliers[tokenIndex]).sub(dy);

    return (dy, dySwapFee);
  }

  /**
   * @notice Calculate the dy of withdrawing in one token
   * @param self Swap struct to read from
   * @param tokenIndex which token will be withdrawn
   * @param tokenAmount the amount to withdraw in the pools precision
   * @return the d and the new y after withdrawing one token
   */
  function calculateWithdrawOneTokenDY(
    Swap storage self,
    uint8 tokenIndex,
    uint256 tokenAmount,
    uint256 totalSupply
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // Get the current D, then solve the stableswap invariant
    // y_i for D - tokenAmount
    uint256[] memory xp = _xp(self);

    require(tokenIndex < xp.length, "Token index out of range");

    CalculateWithdrawOneTokenDYInfo memory v = CalculateWithdrawOneTokenDYInfo(0, 0, 0, 0, 0);
    v.preciseA = _getAPrecise(self);
    v.d0 = getD(xp, v.preciseA);
    v.d1 = v.d0.sub(tokenAmount.mul(v.d0).div(totalSupply));

    require(tokenAmount <= xp[tokenIndex], "Withdraw exceeds available");

    v.newY = getYD(v.preciseA, tokenIndex, xp, v.d1);

    uint256[] memory xpReduced = new uint256[](xp.length);

    v.feePerToken = _feePerToken(self.swapFee, xp.length);
    for (uint256 i = 0; i < xp.length; i++) {
      uint256 xpi = xp[i];
      // if i == tokenIndex, dxExpected = xp[i] * d1 / d0 - newY
      // else dxExpected = xp[i] - (xp[i] * d1 / d0)
      // xpReduced[i] -= dxExpected * fee / FEE_DENOMINATOR
      xpReduced[i] = xpi.sub(
        ((i == tokenIndex) ? xpi.mul(v.d1).div(v.d0).sub(v.newY) : xpi.sub(xpi.mul(v.d1).div(v.d0)))
          .mul(v.feePerToken)
          .div(FEE_DENOMINATOR)
      );
    }

    uint256 dy = xpReduced[tokenIndex].sub(getYD(v.preciseA, tokenIndex, xpReduced, v.d1));
    dy = dy.sub(1).div(self.tokenPrecisionMultipliers[tokenIndex]);

    return (dy, v.newY, xp[tokenIndex]);
  }

  /**
   * @notice Calculate the price of a token in the pool with given
   * precision-adjusted balances and a particular D.
   *
   * @dev This is accomplished via solving the invariant iteratively.
   * See the StableSwap paper and Curve.fi implementation for further details.
   *
   * x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
   * x_1**2 + b*x_1 = c
   * x_1 = (x_1**2 + c) / (2*x_1 + b)
   *
   * @param a the amplification coefficient * n * (n - 1). See the StableSwap paper for details.
   * @param tokenIndex Index of token we are calculating for.
   * @param xp a precision-adjusted set of pool balances. Array should be
   * the same cardinality as the pool.
   * @param d the stableswap invariant
   * @return the price of the token, in the same precision as in xp
   */
  function getYD(
    uint256 a,
    uint8 tokenIndex,
    uint256[] memory xp,
    uint256 d
  ) internal pure returns (uint256) {
    uint256 numTokens = xp.length;
    require(tokenIndex < numTokens, "Token not found");

    uint256 c = d;
    uint256 s;
    uint256 nA = a.mul(numTokens);

    for (uint256 i = 0; i < numTokens; i++) {
      if (i != tokenIndex) {
        s = s.add(xp[i]);
        c = c.mul(d).div(xp[i].mul(numTokens));
        // If we were to protect the division loss we would have to keep the denominator separate
        // and divide at the end. However this leads to overflow with large numTokens or/and D.
        // c = c * D * D * D * ... overflow!
      }
    }
    c = c.mul(d).mul(AmplificationUtils.A_PRECISION).div(nA.mul(numTokens));

    uint256 b = s.add(d.mul(AmplificationUtils.A_PRECISION).div(nA));
    uint256 yPrev;
    uint256 y = d;
    for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
      yPrev = y;
      y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
      if (y.within1(yPrev)) {
        return y;
      }
    }
    revert("Approximation did not converge");
  }

  /**
   * @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
   * @param xp a precision-adjusted set of pool balances. Array should be the same cardinality
   * as the pool.
   * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
   * See the StableSwap paper for details
   * @return the invariant, at the precision of the pool
   */
  function getD(uint256[] memory xp, uint256 a) internal pure returns (uint256) {
    uint256 numTokens = xp.length;
    uint256 s;
    for (uint256 i = 0; i < numTokens; i++) {
      s = s.add(xp[i]);
    }
    if (s == 0) {
      return 0;
    }

    uint256 prevD;
    uint256 d = s;
    uint256 nA = a.mul(numTokens);

    for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
      uint256 dP = d;
      for (uint256 j = 0; j < numTokens; j++) {
        dP = dP.mul(d).div(xp[j].mul(numTokens));
        // If we were to protect the division loss we would have to keep the denominator separate
        // and divide at the end. However this leads to overflow with large numTokens or/and D.
        // dP = dP * D * D * D * ... overflow!
      }
      prevD = d;
      d = nA.mul(s).div(AmplificationUtils.A_PRECISION).add(dP.mul(numTokens)).mul(d).div(
        nA.sub(AmplificationUtils.A_PRECISION).mul(d).div(AmplificationUtils.A_PRECISION).add(numTokens.add(1).mul(dP))
      );
      if (d.within1(prevD)) {
        return d;
      }
    }

    // Convergence should occur in 4 loops or less. If this is reached, there may be something wrong
    // with the pool. If this were to occur repeatedly, LPs should withdraw via `removeLiquidity()`
    // function which does not rely on D.
    revert("D does not converge");
  }

  /**
   * @notice Given a set of balances and precision multipliers, return the
   * precision-adjusted balances.
   *
   * @param balances an array of token balances, in their native precisions.
   * These should generally correspond with pooled tokens.
   *
   * @param precisionMultipliers an array of multipliers, corresponding to
   * the amounts in the balances array. When multiplied together they
   * should yield amounts at the pool's precision.
   *
   * @return an array of amounts "scaled" to the pool's precision
   */
  function _xp(uint256[] memory balances, uint256[] memory precisionMultipliers)
    internal
    pure
    returns (uint256[] memory)
  {
    uint256 numTokens = balances.length;
    require(numTokens == precisionMultipliers.length, "Balances must match multipliers");
    uint256[] memory xp = new uint256[](numTokens);
    for (uint256 i = 0; i < numTokens; i++) {
      xp[i] = balances[i].mul(precisionMultipliers[i]);
    }
    return xp;
  }

  /**
   * @notice Return the precision-adjusted balances of all tokens in the pool
   * @param self Swap struct to read from
   * @return the pool balances "scaled" to the pool's precision, allowing
   * them to be more easily compared.
   */
  function _xp(Swap storage self) internal view returns (uint256[] memory) {
    return _xp(self.balances, self.tokenPrecisionMultipliers);
  }

  /**
   * @notice Get the virtual price, to help calculate profit
   * @param self Swap struct to read from
   * @return the virtual price, scaled to precision of POOL_PRECISION_DECIMALS
   */
  function getVirtualPrice(Swap storage self) external view returns (uint256) {
    uint256 d = getD(_xp(self), _getAPrecise(self));
    LPToken lpToken = self.lpToken;
    uint256 supply = lpToken.totalSupply();
    if (supply > 0) {
      return d.mul(10**uint256(POOL_PRECISION_DECIMALS)).div(supply);
    }
    return 0;
  }

  /**
   * @notice Calculate the new balances of the tokens given the indexes of the token
   * that is swapped from (FROM) and the token that is swapped to (TO).
   * This function is used as a helper function to calculate how much TO token
   * the user should receive on swap.
   *
   * @param preciseA precise form of amplification coefficient
   * @param tokenIndexFrom index of FROM token
   * @param tokenIndexTo index of TO token
   * @param x the new total amount of FROM token
   * @param xp balances of the tokens in the pool
   * @return the amount of TO token that should remain in the pool
   */
  function getY(
    uint256 preciseA,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 x,
    uint256[] memory xp
  ) internal pure returns (uint256) {
    uint256 numTokens = xp.length;
    require(tokenIndexFrom != tokenIndexTo, "Can't compare token to itself");
    require(tokenIndexFrom < numTokens && tokenIndexTo < numTokens, "Tokens must be in pool");

    uint256 d = getD(xp, preciseA);
    uint256 c = d;
    uint256 s;
    uint256 nA = numTokens.mul(preciseA);

    uint256 _x;
    for (uint256 i = 0; i < numTokens; i++) {
      if (i == tokenIndexFrom) {
        _x = x;
      } else if (i != tokenIndexTo) {
        _x = xp[i];
      } else {
        continue;
      }
      s = s.add(_x);
      c = c.mul(d).div(_x.mul(numTokens));
      // If we were to protect the division loss we would have to keep the denominator separate
      // and divide at the end. However this leads to overflow with large numTokens or/and D.
      // c = c * D * D * D * ... overflow!
    }
    c = c.mul(d).mul(AmplificationUtils.A_PRECISION).div(nA.mul(numTokens));
    uint256 b = s.add(d.mul(AmplificationUtils.A_PRECISION).div(nA));
    uint256 yPrev;
    uint256 y = d;

    // iterative approximation
    for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
      yPrev = y;
      y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
      if (y.within1(yPrev)) {
        return y;
      }
    }
    revert("Approximation did not converge");
  }

  /**
   * @notice Externally calculates a swap between two tokens.
   * @param self Swap struct to read from
   * @param tokenIndexFrom the token to sell
   * @param tokenIndexTo the token to buy
   * @param dx the number of tokens to sell. If the token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @return dy the number of tokens the user will get
   */
  function calculateSwap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256 dy) {
    (dy, ) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx, self.balances);
  }

  /**
   * @notice Internally calculates a swap between two tokens.
   *
   * @dev The caller is expected to transfer the actual amounts (dx and dy)
   * using the token contracts.
   *
   * @param self Swap struct to read from
   * @param tokenIndexFrom the token to sell
   * @param tokenIndexTo the token to buy
   * @param dx the number of tokens to sell. If the token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @return dy the number of tokens the user will get
   * @return dyFee the associated fee
   */
  function _calculateSwap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256[] memory balances
  ) internal view returns (uint256 dy, uint256 dyFee) {
    uint256[] memory multipliers = self.tokenPrecisionMultipliers;
    uint256[] memory xp = _xp(balances, multipliers);
    require(tokenIndexFrom < xp.length && tokenIndexTo < xp.length, "Token index out of range");
    uint256 x = dx.mul(multipliers[tokenIndexFrom]).add(xp[tokenIndexFrom]);
    uint256 y = getY(_getAPrecise(self), tokenIndexFrom, tokenIndexTo, x, xp);
    dy = xp[tokenIndexTo].sub(y).sub(1);
    dyFee = dy.mul(self.swapFee).div(FEE_DENOMINATOR);
    dy = dy.sub(dyFee).div(multipliers[tokenIndexTo]);
  }

  /**
   * @notice A simple method to calculate amount of each underlying
   * tokens that is returned upon burning given amount of
   * LP tokens
   *
   * @param amount the amount of LP tokens that would to be burned on
   * withdrawal
   * @return array of amounts of tokens user will receive
   */
  function calculateRemoveLiquidity(Swap storage self, uint256 amount) external view returns (uint256[] memory) {
    return _calculateRemoveLiquidity(self.balances, amount, self.lpToken.totalSupply());
  }

  function _calculateRemoveLiquidity(
    uint256[] memory balances,
    uint256 amount,
    uint256 totalSupply
  ) internal pure returns (uint256[] memory) {
    require(amount <= totalSupply, "Cannot exceed total supply");

    uint256[] memory amounts = new uint256[](balances.length);

    for (uint256 i = 0; i < balances.length; i++) {
      amounts[i] = balances[i].mul(amount).div(totalSupply);
    }
    return amounts;
  }

  /**
   * @notice A simple method to calculate prices from deposits or
   * withdrawals, excluding fees but including slippage. This is
   * helpful as an input into the various "min" parameters on calls
   * to fight front-running
   *
   * @dev This shouldn't be used outside frontends for user estimates.
   *
   * @param self Swap struct to read from
   * @param amounts an array of token amounts to deposit or withdrawal,
   * corresponding to pooledTokens. The amount should be in each
   * pooled token's native precision. If a token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @param deposit whether this is a deposit or a withdrawal
   * @return if deposit was true, total amount of lp token that will be minted and if
   * deposit was false, total amount of lp token that will be burned
   */
  function calculateTokenAmount(
    Swap storage self,
    uint256[] calldata amounts,
    bool deposit
  ) external view returns (uint256) {
    uint256 a = _getAPrecise(self);
    uint256[] memory balances = self.balances;
    uint256[] memory multipliers = self.tokenPrecisionMultipliers;

    uint256 d0 = getD(_xp(balances, multipliers), a);
    for (uint256 i = 0; i < balances.length; i++) {
      if (deposit) {
        balances[i] = balances[i].add(amounts[i]);
      } else {
        balances[i] = balances[i].sub(amounts[i], "Cannot withdraw more than available");
      }
    }
    uint256 d1 = getD(_xp(balances, multipliers), a);
    uint256 totalSupply = self.lpToken.totalSupply();

    if (deposit) {
      return d1.sub(d0).mul(totalSupply).div(d0);
    } else {
      return d0.sub(d1).mul(totalSupply).div(d0);
    }
  }

  /**
   * @notice return accumulated amount of admin fees of the token with given index
   * @param self Swap struct to read from
   * @param index Index of the pooled token
   * @return admin balance in the token's precision
   */
  function getAdminBalance(Swap storage self, uint256 index) external view returns (uint256) {
    require(index < self.pooledTokens.length, "Token index out of range");
    return self.pooledTokens[index].balanceOf(address(this)).sub(self.balances[index]);
  }

  /**
   * @notice internal helper function to calculate fee per token multiplier used in
   * swap fee calculations
   * @param swapFee swap fee for the tokens
   * @param numTokens number of tokens pooled
   */
  function _feePerToken(uint256 swapFee, uint256 numTokens) internal pure returns (uint256) {
    return swapFee.mul(numTokens).div(numTokens.sub(1).mul(4));
  }

  /*** STATE MODIFYING FUNCTIONS ***/

  /**
   * @notice swap two tokens in the pool
   * @param self Swap struct to read from and write to
   * @param tokenIndexFrom the token the user wants to sell
   * @param tokenIndexTo the token the user wants to buy
   * @param dx the amount of tokens the user wants to sell
   * @param minDy the min amount the user would like to receive, or revert.
   * @return amount of token user received on swap
   */
  function swap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy
  ) external returns (uint256) {
    {
      IERC20 tokenFrom = self.pooledTokens[tokenIndexFrom];
      require(dx <= tokenFrom.balanceOf(msg.sender), "Cannot swap more than you own");
      // Transfer tokens first to see if a fee was charged on transfer
      uint256 beforeBalance = tokenFrom.balanceOf(address(this));
      tokenFrom.safeTransferFrom(msg.sender, address(this), dx);

      // Use the actual transferred amount for AMM math
      dx = tokenFrom.balanceOf(address(this)).sub(beforeBalance);
    }

    uint256 dy;
    uint256 dyFee;
    uint256[] memory balances = self.balances;
    (dy, dyFee) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx, balances);
    require(dy >= minDy, "Swap didn't result in min tokens");

    uint256 dyAdminFee = dyFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(
      self.tokenPrecisionMultipliers[tokenIndexTo]
    );

    self.balances[tokenIndexFrom] = balances[tokenIndexFrom].add(dx);
    self.balances[tokenIndexTo] = balances[tokenIndexTo].sub(dy).sub(dyAdminFee);

    self.pooledTokens[tokenIndexTo].safeTransfer(msg.sender, dy);

    emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

    return dy;
  }

  /**
   * @notice Add liquidity to the pool
   * @param self Swap struct to read from and write to
   * @param amounts the amounts of each token to add, in their native precision
   * @param minToMint the minimum LP tokens adding this amount of liquidity
   * should mint, otherwise revert. Handy for front-running mitigation
   * allowed addresses. If the pool is not in the guarded launch phase, this parameter will be ignored.
   * @return amount of LP token user received
   */
  function addLiquidity(
    Swap storage self,
    uint256[] memory amounts,
    uint256 minToMint
  ) external returns (uint256) {
    IERC20[] memory pooledTokens = self.pooledTokens;
    require(amounts.length == pooledTokens.length, "Amounts must match pooled tokens");

    // current state
    ManageLiquidityInfo memory v = ManageLiquidityInfo(
      0,
      0,
      0,
      _getAPrecise(self),
      self.lpToken,
      0,
      self.balances,
      self.tokenPrecisionMultipliers
    );
    v.totalSupply = v.lpToken.totalSupply();

    if (v.totalSupply != 0) {
      v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
    }

    uint256[] memory newBalances = new uint256[](pooledTokens.length);

    for (uint256 i = 0; i < pooledTokens.length; i++) {
      require(v.totalSupply != 0 || amounts[i] > 0, "Must supply all tokens in pool");

      // Transfer tokens first to see if a fee was charged on transfer
      if (amounts[i] != 0) {
        uint256 beforeBalance = pooledTokens[i].balanceOf(address(this));
        pooledTokens[i].safeTransferFrom(msg.sender, address(this), amounts[i]);

        // Update the amounts[] with actual transfer amount
        amounts[i] = pooledTokens[i].balanceOf(address(this)).sub(beforeBalance);
      }

      newBalances[i] = v.balances[i].add(amounts[i]);
    }

    // invariant after change
    v.d1 = getD(_xp(newBalances, v.multipliers), v.preciseA);
    require(v.d1 > v.d0, "D should increase");

    // updated to reflect fees and calculate the user's LP tokens
    v.d2 = v.d1;
    uint256[] memory fees = new uint256[](pooledTokens.length);

    if (v.totalSupply != 0) {
      uint256 feePerToken = _feePerToken(self.swapFee, pooledTokens.length);
      for (uint256 i = 0; i < pooledTokens.length; i++) {
        uint256 idealBalance = v.d1.mul(v.balances[i]).div(v.d0);
        fees[i] = feePerToken.mul(idealBalance.difference(newBalances[i])).div(FEE_DENOMINATOR);
        self.balances[i] = newBalances[i].sub(fees[i].mul(self.adminFee).div(FEE_DENOMINATOR));
        newBalances[i] = newBalances[i].sub(fees[i]);
      }
      v.d2 = getD(_xp(newBalances, v.multipliers), v.preciseA);
    } else {
      // the initial depositor doesn't pay fees
      self.balances = newBalances;
    }

    uint256 toMint;
    if (v.totalSupply == 0) {
      toMint = v.d1;
    } else {
      toMint = v.d2.sub(v.d0).mul(v.totalSupply).div(v.d0);
    }

    require(toMint >= minToMint, "Couldn't mint min requested");

    // mint the user's LP tokens
    v.lpToken.mint(msg.sender, toMint);

    emit AddLiquidity(msg.sender, amounts, fees, v.d1, v.totalSupply.add(toMint));

    return toMint;
  }

  /**
   * @notice Burn LP tokens to remove liquidity from the pool.
   * @dev Liquidity can always be removed, even when the pool is paused.
   * @param self Swap struct to read from and write to
   * @param amount the amount of LP tokens to burn
   * @param minAmounts the minimum amounts of each token in the pool
   * acceptable for this burn. Useful as a front-running mitigation
   * @return amounts of tokens the user received
   */
  function removeLiquidity(
    Swap storage self,
    uint256 amount,
    uint256[] calldata minAmounts
  ) external returns (uint256[] memory) {
    LPToken lpToken = self.lpToken;
    IERC20[] memory pooledTokens = self.pooledTokens;
    require(amount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
    require(minAmounts.length == pooledTokens.length, "minAmounts must match poolTokens");

    uint256[] memory balances = self.balances;
    uint256 totalSupply = lpToken.totalSupply();

    uint256[] memory amounts = _calculateRemoveLiquidity(balances, amount, totalSupply);

    for (uint256 i = 0; i < amounts.length; i++) {
      require(amounts[i] >= minAmounts[i], "amounts[i] < minAmounts[i]");
      self.balances[i] = balances[i].sub(amounts[i]);
      pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
    }

    lpToken.burnFrom(msg.sender, amount);

    emit RemoveLiquidity(msg.sender, amounts, totalSupply.sub(amount));

    return amounts;
  }

  /**
   * @notice Remove liquidity from the pool all in one token.
   * @param self Swap struct to read from and write to
   * @param tokenAmount the amount of the lp tokens to burn
   * @param tokenIndex the index of the token you want to receive
   * @param minAmount the minimum amount to withdraw, otherwise revert
   * @return amount chosen token that user received
   */
  function removeLiquidityOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount
  ) external returns (uint256) {
    LPToken lpToken = self.lpToken;
    IERC20[] memory pooledTokens = self.pooledTokens;

    require(tokenAmount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
    require(tokenIndex < pooledTokens.length, "Token not found");

    uint256 totalSupply = lpToken.totalSupply();

    (uint256 dy, uint256 dyFee) = _calculateWithdrawOneToken(self, tokenAmount, tokenIndex, totalSupply);

    require(dy >= minAmount, "dy < minAmount");

    self.balances[tokenIndex] = self.balances[tokenIndex].sub(dy.add(dyFee.mul(self.adminFee).div(FEE_DENOMINATOR)));
    lpToken.burnFrom(msg.sender, tokenAmount);
    pooledTokens[tokenIndex].safeTransfer(msg.sender, dy);

    emit RemoveLiquidityOne(msg.sender, tokenAmount, totalSupply, tokenIndex, dy);

    return dy;
  }

  /**
   * @notice Remove liquidity from the pool, weighted differently than the
   * pool's current balances.
   *
   * @param self Swap struct to read from and write to
   * @param amounts how much of each token to withdraw
   * @param maxBurnAmount the max LP token provider is willing to pay to
   * remove liquidity. Useful as a front-running mitigation.
   * @return actual amount of LP tokens burned in the withdrawal
   */
  function removeLiquidityImbalance(
    Swap storage self,
    uint256[] memory amounts,
    uint256 maxBurnAmount
  ) public returns (uint256) {
    ManageLiquidityInfo memory v = ManageLiquidityInfo(
      0,
      0,
      0,
      _getAPrecise(self),
      self.lpToken,
      0,
      self.balances,
      self.tokenPrecisionMultipliers
    );
    v.totalSupply = v.lpToken.totalSupply();

    IERC20[] memory pooledTokens = self.pooledTokens;

    require(amounts.length == pooledTokens.length, "Amounts should match pool tokens");

    require(maxBurnAmount <= v.lpToken.balanceOf(msg.sender) && maxBurnAmount != 0, ">LP.balanceOf");

    uint256 feePerToken = _feePerToken(self.swapFee, pooledTokens.length);
    uint256[] memory fees = new uint256[](pooledTokens.length);
    {
      uint256[] memory balances1 = new uint256[](pooledTokens.length);
      v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
      for (uint256 i = 0; i < pooledTokens.length; i++) {
        balances1[i] = v.balances[i].sub(amounts[i], "Cannot withdraw more than available");
      }
      v.d1 = getD(_xp(balances1, v.multipliers), v.preciseA);

      for (uint256 i = 0; i < pooledTokens.length; i++) {
        uint256 idealBalance = v.d1.mul(v.balances[i]).div(v.d0);
        uint256 difference = idealBalance.difference(balances1[i]);
        fees[i] = feePerToken.mul(difference).div(FEE_DENOMINATOR);
        self.balances[i] = balances1[i].sub(fees[i].mul(self.adminFee).div(FEE_DENOMINATOR));
        balances1[i] = balances1[i].sub(fees[i]);
      }

      v.d2 = getD(_xp(balances1, v.multipliers), v.preciseA);
    }
    uint256 tokenAmount = v.d0.sub(v.d2).mul(v.totalSupply).div(v.d0);
    require(tokenAmount != 0, "Burnt amount cannot be zero");
    tokenAmount = tokenAmount.add(1);

    require(tokenAmount <= maxBurnAmount, "tokenAmount > maxBurnAmount");

    v.lpToken.burnFrom(msg.sender, tokenAmount);

    for (uint256 i = 0; i < pooledTokens.length; i++) {
      pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
    }

    emit RemoveLiquidityImbalance(msg.sender, amounts, fees, v.d1, v.totalSupply.sub(tokenAmount));

    return tokenAmount;
  }

  /**
   * @notice withdraw all admin fees to a given address
   * @param self Swap struct to withdraw fees from
   * @param to Address to send the fees to
   */
  function withdrawAdminFees(Swap storage self, address to) external {
    IERC20[] memory pooledTokens = self.pooledTokens;
    for (uint256 i = 0; i < pooledTokens.length; i++) {
      IERC20 token = pooledTokens[i];
      uint256 balance = token.balanceOf(address(this)).sub(self.balances[i]);
      if (balance != 0) {
        token.safeTransfer(to, balance);
      }
    }
  }

  /**
   * @notice Sets the admin fee
   * @dev adminFee cannot be higher than 100% of the swap fee
   * @param self Swap struct to update
   * @param newAdminFee new admin fee to be applied on future transactions
   */
  function setAdminFee(Swap storage self, uint256 newAdminFee) external {
    require(newAdminFee <= MAX_ADMIN_FEE, "Fee is too high");
    self.adminFee = newAdminFee;

    emit NewAdminFee(newAdminFee);
  }

  /**
   * @notice update the swap fee
   * @dev fee cannot be higher than 1% of each swap
   * @param self Swap struct to update
   * @param newSwapFee new swap fee to be applied on future transactions
   */
  function setSwapFee(Swap storage self, uint256 newSwapFee) external {
    require(newSwapFee <= MAX_SWAP_FEE, "Fee is too high");
    self.swapFee = newSwapFee;

    emit NewSwapFee(newSwapFee);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title MathUtils library
 * @notice A library to be used in conjunction with SafeMath. Contains functions for calculating
 * differences between two uint256.
 */
library MathUtils {
  /**
   * @notice Compares a and b and returns true if the difference between a and b
   *         is less than 1 or equal to each other.
   * @param a uint256 to compare with
   * @param b uint256 to compare with
   * @return True if the difference between a and b is less than 1 or equal,
   *         otherwise return false
   */
  function within1(uint256 a, uint256 b) internal pure returns (bool) {
    return (difference(a, b) <= 1);
  }

  /**
   * @notice Calculates absolute difference between a and b
   * @param a uint256 to compare with
   * @param b uint256 to compare with
   * @return Difference between a and b
   */
  function difference(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) {
      return a - b;
    }
    return b - a;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../interfaces/IStableSwap.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * This contract is designed to be used in tests *only*!! Has no logic about
 * reserves, simply swaps assets 1:1 based on reserves to simplify test assertions
 */
contract DummySwap is IStableSwap {
  constructor() {}

  event PoolCreated(address assetA, address assetB, uint256 seedA, uint256 seedB);

  event Swapped(address indexed buyer, uint256 amountIn, uint256 amountOut, address assetIn, address assetOut);

  // Hold mapping of swaps
  mapping(address => address) poolAssets;

  receive() external payable {}

  function swapExact(
    uint256 amountIn,
    address assetIn,
    address assetOut
  ) external payable returns (uint256) {
    // make sure pool is setup
    require(poolAssets[assetIn] == assetOut, "!setup");

    // make sure theres enough balance
    bool assetOutIsNative = assetOut == address(0);
    if (assetOutIsNative) {
      require(address(this).balance >= amountIn, "!bal");
    } else {
      require(IERC20(assetOut).balanceOf(address(this)) >= amountIn, "!bal");
    }

    // transfer in (simple 1:1)
    if (assetIn == address(0)) {
      require(msg.value == amountIn, "!val");
    } else {
      SafeERC20.safeTransferFrom(IERC20(assetIn), msg.sender, address(this), amountIn);
    }

    // transfer out (simple 1:1)
    if (assetOutIsNative) {
      Address.sendValue(payable(msg.sender), amountIn);
    } else {
      SafeERC20.safeTransfer(IERC20(assetOut), msg.sender, amountIn);
    }

    // emit
    emit Swapped(msg.sender, amountIn, amountIn, assetIn, assetOut);

    return amountIn;
  }

  function getA() external view returns (uint256) {
    require(false, "!implemented");
  }

  function getToken(uint8 index) external view returns (IERC20) {
    require(false, "!implemented");
  }

  function getTokenIndex(address tokenAddress) external view returns (uint8) {
    require(false, "!implemented");
  }

  function getTokenBalance(uint8 index) external view returns (uint256) {
    require(false, "!implemented");
  }

  function getVirtualPrice() external view returns (uint256) {
    require(false, "!implemented");
  }

  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256) {
    require(false, "!implemented");
  }

  function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256) {
    require(false, "!implemented");
  }

  function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory) {
    require(false, "!implemented");
  }

  function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
    external
    view
    returns (uint256 availableTokenAmount)
  {
    require(false, "!implemented");
  }

  function initialize(
    IERC20[] memory pooledTokens,
    uint8[] memory decimals,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    uint256 a,
    uint256 fee,
    uint256 adminFee,
    address lpTokenTargetAddress
  ) external {
    require(false, "!implemented");
  }

  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external returns (uint256) {
    require(false, "!implemented");
  }

  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external returns (uint256) {
    require(false, "!implemented");
  }

  function removeLiquidity(
    uint256 amount,
    uint256[] calldata minAmounts,
    uint256 deadline
  ) external returns (uint256[] memory) {
    require(false, "!implemented");
  }

  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256) {
    require(false, "!implemented");
  }

  function removeLiquidityImbalance(
    uint256[] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external returns (uint256) {
    require(false, "!implemented");
  }

  function setupPool(
    address assetA,
    address assetB,
    uint256 seedA,
    uint256 seedB
  ) external payable {
    // Save pool to swap A <-> B
    poolAssets[assetA] = assetB;
    poolAssets[assetB] = assetA;

    // Transfer funds to contract
    if (assetA == address(0)) {
      require(msg.value == seedA, "!seedA");
    } else {
      SafeERC20.safeTransferFrom(IERC20(assetA), msg.sender, address(this), seedA);
    }

    if (assetB == address(0)) {
      require(msg.value == seedB, "!seedB");
    } else {
      SafeERC20.safeTransferFrom(IERC20(assetB), msg.sender, address(this), seedB);
    }

    emit PoolCreated(assetA, assetB, seedA, seedB);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {UpgradeBeacon} from "./UpgradeBeacon.sol";
// ============ External Imports ============
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title UpgradeBeaconController
 * @notice Set as the controller of UpgradeBeacon contract(s),
 * capable of changing their stored implementation address.
 * @dev This implementation is a minimal version inspired by 0age's implementation:
 * https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/upgradeability/DharmaUpgradeBeaconController.sol
 */
contract UpgradeBeaconController is Ownable {
  // ============ Events ============

  event BeaconUpgraded(address indexed beacon, address implementation);

  // ============ External Functions ============

  /**
   * @notice Modify the implementation stored in the UpgradeBeacon,
   * which will upgrade the implementation used by all
   * Proxy contracts using that UpgradeBeacon
   * @param _beacon Address of the UpgradeBeacon which will be updated
   * @param _implementation Address of the Implementation contract to upgrade the Beacon to
   */
  function upgrade(address _beacon, address _implementation) external onlyOwner {
    // Require that the beacon is a contract
    require(Address.isContract(_beacon), "beacon !contract");
    // Call into beacon and supply address of new implementation to update it.
    (bool _success, ) = _beacon.call(abi.encode(_implementation));
    // Revert with message on failure (i.e. if the beacon is somehow incorrect).
    if (!_success) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
    emit BeaconUpgraded(_beacon, _implementation);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

// ============ External Imports ============
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title UpgradeBeacon
 * @notice Stores the address of an implementation contract
 * and allows a controller to upgrade the implementation address
 * @dev This implementation combines the gas savings of having no function selectors
 * found in 0age's implementation:
 * https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/proxies/smart-wallet/UpgradeBeaconProxyV1.sol
 * With the added niceties of a safety check that each implementation is a contract
 * and an Upgrade event emitted each time the implementation is changed
 * found in OpenZeppelin's implementation:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/beacon/BeaconProxy.sol
 */
contract UpgradeBeacon {
  // ============ Immutables ============

  // The controller is capable of modifying the implementation address
  address private immutable controller;

  // ============ Private Storage Variables ============

  // The implementation address is held in storage slot zero.
  address private implementation;

  // ============ Events ============

  // Upgrade event is emitted each time the implementation address is set
  // (including deployment)
  event Upgrade(address indexed implementation);

  // ============ Constructor ============

  /**
   * @notice Validate the initial implementation and store it.
   * Store the controller immutably.
   * @param _initialImplementation Address of the initial implementation contract
   * @param _controller Address of the controller who can upgrade the implementation
   */
  constructor(address _initialImplementation, address _controller) payable {
    _setImplementation(_initialImplementation);
    controller = _controller;
  }

  // ============ External Functions ============

  /**
   * @notice For all callers except the controller, return the current implementation address.
   * If called by the Controller, update the implementation address
   * to the address passed in the calldata.
   * Note: this requires inline assembly because Solidity fallback functions
   * do not natively take arguments or return values.
   */
  fallback() external payable {
    if (msg.sender != controller) {
      // if not called by the controller,
      // load implementation address from storage slot zero
      // and return it.
      assembly {
        mstore(0, sload(0))
        return(0, 32)
      }
    } else {
      // if called by the controller,
      // load new implementation address from the first word of the calldata
      address _newImplementation;
      assembly {
        _newImplementation := calldataload(0)
      }
      // set the new implementation
      _setImplementation(_newImplementation);
    }
  }

  // ============ Private Functions ============

  /**
   * @notice Perform checks on the new implementation address
   * then upgrade the stored implementation.
   * @param _newImplementation Address of the new implementation contract which will replace the old one
   */
  function _setImplementation(address _newImplementation) private {
    // Require that the new implementation is different from the current one
    require(implementation != _newImplementation, "!upgrade");
    // Require that the new implementation is a contract
    require(Address.isContract(_newImplementation), "implementation !contract");
    // set the new implementation
    implementation = _newImplementation;
    emit Upgrade(_newImplementation);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Generic ERC20 token
 * @notice This contract simulates a generic ERC20 token that is mintable and burnable.
 */
contract GenericERC20 is ERC20, Ownable {
  /**
   * @notice Deploy this contract with given name, symbol, and decimals
   * @dev the caller of this constructor will become the owner of this contract
   * @param name_ name of this token
   * @param symbol_ symbol of this token
   */
  constructor(string memory name_, string memory symbol_) public ERC20(name_, symbol_) {}

  /**
   * @notice Mints given amount of tokens to recipient
   * @dev only owner can call this mint function
   * @param recipient address of account to receive the tokens
   * @param amount amount of tokens to mint
   */
  function mint(address recipient, uint256 amount) external onlyOwner {
    require(amount != 0, "amount == 0");
    _mint(recipient, amount);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {IUpdaterManager} from "../interfaces/IUpdaterManager.sol";
import {Home} from "./Home.sol";
// ============ External Imports ============
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title UpdaterManager
 * @author Illusory Systems Inc.
 * @notice MVP / centralized version of contract
 * that will manage Updater bonding, slashing,
 * selection and rotation
 */
contract UpdaterManager is IUpdaterManager, Ownable {
  // ============ Internal Storage ============

  // address of home contract
  address internal home;

  // ============ Private Storage ============

  // address of the current updater
  address private _updater;

  // ============ Events ============

  /**
   * @notice Emitted when a new home is set
   * @param home The address of the new home contract
   */
  event NewHome(address home);

  /**
   * @notice Emitted when slashUpdater is called
   */
  event FakeSlashed(address reporter);

  // ============ Modifiers ============

  /**
   * @notice Require that the function is called
   * by the Home contract
   */
  modifier onlyHome() {
    require(msg.sender == home, "!home");
    _;
  }

  // ============ Constructor ============

  constructor(address _updaterAddress) payable Ownable() {
    _updater = _updaterAddress;
  }

  // ============ External Functions ============

  /**
   * @notice Set the address of the a new home contract
   * @dev only callable by trusted owner
   * @param _home The address of the new home contract
   */
  function setHome(address _home) external onlyOwner {
    require(Address.isContract(_home), "!contract home");
    home = _home;

    emit NewHome(_home);
  }

  /**
   * @notice Set the address of a new updater
   * @dev only callable by trusted owner
   * @param _updaterAddress The address of the new updater
   */
  function setUpdater(address _updaterAddress) external onlyOwner {
    _updater = _updaterAddress;
    Home(home).setUpdater(_updaterAddress);
  }

  /**
   * @notice Slashes the updater
   * @dev Currently does nothing, functionality will be implemented later
   * when updater bonding and rotation are also implemented
   * @param _reporter The address of the entity that reported the updater fraud
   */
  function slashUpdater(address payable _reporter) external override onlyHome {
    emit FakeSlashed(_reporter);
  }

  /**
   * @notice Get address of current updater
   * @return the updater address
   */
  function updater() external view override returns (address) {
    return _updater;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

// ============ Internal Imports ============
import {Home} from "../Home.sol";
import {Version0} from "../Version0.sol";
import {XAppConnectionManager, TypeCasts} from "../XAppConnectionManager.sol";
import {IMessageRecipient} from "../../interfaces/IMessageRecipient.sol";
import {GovernanceMessage} from "./GovernanceMessage.sol";
// ============ External Imports ============
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import {TypedMemView} from "@summa-tx/memview-sol/contracts/TypedMemView.sol";
import {TypedMemView} from "../../libs/TypedMemView.sol";

contract GovernanceRouter is Version0, Initializable, IMessageRecipient {
  // ============ Libraries ============

  using SafeMath for uint256;
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using GovernanceMessage for bytes29;

  // ============== Enums ==============

  // The status of a batch of governance calls
  enum BatchStatus {
    Unknown, // 0
    Pending, // 1
    Complete // 2
  }

  // ============ Immutables ============

  uint32 public immutable localDomain;
  // number of seconds before recovery can be activated
  uint256 public immutable recoveryTimelock;

  // ============ Public Storage ============

  // timestamp when recovery timelock expires; 0 if timelock has not been initiated
  uint256 public recoveryActiveAt;
  // the address of the recovery manager multisig
  address public recoveryManager;
  // the local entity empowered to call governance functions, set to 0x0 on non-Governor chains
  address public governor;
  // domain of Governor chain -- for accepting incoming messages from Governor
  uint32 public governorDomain;
  // xAppConnectionManager contract which stores Replica addresses
  XAppConnectionManager public xAppConnectionManager;
  // domain -> remote GovernanceRouter contract address
  mapping(uint32 => bytes32) public routers;
  // array of all domains with registered GovernanceRouter
  uint32[] public domains;
  // call hash -> call status
  mapping(bytes32 => BatchStatus) public inboundCallBatches;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[42] private __GAP;

  // ============ Events ============

  /**
   * @notice Emitted a remote GovernanceRouter address is added, removed, or changed
   * @param domain the domain of the remote Router
   * @param previousRouter the previously registered router; 0 if router is being added
   * @param newRouter the new registered router; 0 if router is being removed
   */
  event SetRouter(uint32 indexed domain, bytes32 previousRouter, bytes32 newRouter);

  /**
   * @notice Emitted when the Governor role is transferred
   * @param previousGovernorDomain the domain of the previous Governor
   * @param newGovernorDomain the domain of the new Governor
   * @param previousGovernor the address of the previous Governor; 0 if the governor was remote
   * @param newGovernor the address of the new Governor; 0 if the governor is remote
   */
  event TransferGovernor(
    uint32 previousGovernorDomain,
    uint32 newGovernorDomain,
    address indexed previousGovernor,
    address indexed newGovernor
  );

  /**
   * @notice Emitted when the RecoveryManager role is transferred
   * @param previousRecoveryManager the address of the previous RecoveryManager
   * @param newRecoveryManager the address of the new RecoveryManager
   */
  event TransferRecoveryManager(address indexed previousRecoveryManager, address indexed newRecoveryManager);

  /**
   * @notice Emitted when recovery state is initiated by the RecoveryManager
   * @param recoveryManager the address of the current RecoveryManager who
   * initiated the transition
   * @param recoveryActiveAt the block at which recovery state will be active
   */
  event InitiateRecovery(address indexed recoveryManager, uint256 recoveryActiveAt);

  /**
   * @notice Emitted when recovery state is exited by the RecoveryManager
   * @param recoveryManager the address of the current RecoveryManager who
   * initiated the transition
   */
  event ExitRecovery(address recoveryManager);

  /**
   * @notice Emitted when a batch of governance instructions from the
   * governing remote router is received and ready for execution
   * @param batchHash A hash committing to the batch of calls to be executed
   */
  event BatchReceived(bytes32 indexed batchHash);

  /**
   * @notice Emitted when a batch of governance instructions from the
   * governing remote router is executed
   * @param batchHash A hash committing to the batch of calls to be executed
   */
  event BatchExecuted(bytes32 indexed batchHash);

  modifier typeAssert(bytes29 _view, GovernanceMessage.Types _type) {
    _view.assertType(uint40(_type));
    _;
  }

  // ============ Modifiers ============

  modifier onlyReplica() {
    require(xAppConnectionManager.isReplica(msg.sender), "!replica");
    _;
  }

  modifier onlyGovernorRouter(uint32 _domain, bytes32 _address) {
    require(_isGovernorRouter(_domain, _address), "!governorRouter");
    _;
  }

  modifier onlyGovernor() {
    require(msg.sender == governor || msg.sender == address(this), "! called by governor");
    _;
  }

  modifier onlyRecoveryManager() {
    require(msg.sender == recoveryManager, "! called by recovery manager");
    _;
  }

  modifier onlyInRecovery() {
    require(inRecovery(), "! in recovery");
    _;
  }

  modifier onlyNotInRecovery() {
    require(!inRecovery(), "in recovery");
    _;
  }

  modifier onlyGovernorOrRecoveryManager() {
    if (!inRecovery()) {
      require(msg.sender == governor || msg.sender == address(this), "! called by governor");
    } else {
      require(msg.sender == recoveryManager || msg.sender == address(this), "! called by recovery manager");
    }
    _;
  }

  // ============ Constructor ============

  constructor(uint32 _localDomain, uint256 _recoveryTimelock) {
    localDomain = _localDomain;
    recoveryTimelock = _recoveryTimelock;
  }

  // ============ Initializer ============

  function initialize(address _xAppConnectionManager, address _recoveryManager) public initializer {
    // initialize governor
    address _governorAddr = msg.sender;
    bool _isLocalGovernor = true;
    _transferGovernor(localDomain, _governorAddr, _isLocalGovernor);
    // initialize recovery manager
    recoveryManager = _recoveryManager;
    // initialize XAppConnectionManager
    setXAppConnectionManager(_xAppConnectionManager);
    require(xAppConnectionManager.localDomain() == localDomain, "XAppConnectionManager bad domain");
  }

  // ============ External Functions ============

  /**
   * @notice Handle Nomad messages
   * For all non-Governor chains to handle messages
   * sent from the Governor chain via Nomad.
   * Governor chain should never receive messages,
   * because non-Governor chains are not able to send them
   * @param _origin The domain (of the Governor Router)
   * @param _sender The message sender (must be the Governor Router)
   * @param _message The message
   */
  function handle(
    uint32 _origin,
    uint32, // _nonce (unused)
    bytes32 _sender,
    bytes memory _message
  ) external override onlyReplica onlyGovernorRouter(_origin, _sender) {
    bytes29 _msg = _message.ref(0);
    bytes29 _view = _msg.tryAsBatch();
    if (_view.notNull()) {
      _handleBatch(_view);
      return;
    }
    _view = _msg.tryAsTransferGovernor();
    if (_view.notNull()) {
      _handleTransferGovernor(_view);
      return;
    }
    require(false, "!valid message type");
  }

  /**
   * @notice Dispatch a set of local and remote calls
   * Local calls are executed immediately.
   * Remote calls are dispatched to the remote domain for processing and
   * execution.
   * @dev The contents of the _domains array at the same index
   * will determine the destination of messages in that _remoteCalls array.
   * As such, all messages in an array MUST have the same destination.
   * Missing destinations or too many will result in reverts.
   * @param _localCalls An array of local calls
   * @param _remoteCalls An array of arrays of remote calls
   */
  function executeGovernanceActions(
    GovernanceMessage.Call[] calldata _localCalls,
    uint32[] calldata _domains,
    GovernanceMessage.Call[][] calldata _remoteCalls
  ) external onlyGovernorOrRecoveryManager {
    require(_domains.length == _remoteCalls.length, "!domains length matches calls length");
    // remote calls are disallowed while in recovery
    require(_remoteCalls.length == 0 || !inRecovery(), "!remote calls in recovery mode");
    // _localCall loop
    for (uint256 i = 0; i < _localCalls.length; i++) {
      _callLocal(_localCalls[i]);
    }
    // remote calls loop
    for (uint256 i = 0; i < _remoteCalls.length; i++) {
      uint32 destination = _domains[i];
      _callRemote(destination, _remoteCalls[i]);
    }
  }

  /**
   * @notice Dispatch calls on a remote chain via the remote GovernanceRouter
   * @param _destination The domain of the remote chain
   * @param _calls The calls
   */
  function _callRemote(uint32 _destination, GovernanceMessage.Call[] calldata _calls)
    internal
    onlyGovernor
    onlyNotInRecovery
  {
    // ensure that destination chain has enrolled router
    bytes32 _router = _mustHaveRouter(_destination);
    // format batch message
    bytes memory _msg = GovernanceMessage.formatBatch(_calls);
    // dispatch call message using Nomad
    Home(xAppConnectionManager.home()).dispatch(_destination, _router, _msg);
  }

  /**
   * @notice Transfer governorship
   * @param _newDomain The domain of the new governor
   * @param _newGovernor The address of the new governor
   */
  function transferGovernor(uint32 _newDomain, address _newGovernor) external onlyGovernor onlyNotInRecovery {
    bool _isLocalGovernor = _isLocalDomain(_newDomain);
    // transfer the governor locally
    _transferGovernor(_newDomain, _newGovernor, _isLocalGovernor);
    // if the governor domain is local, we only need to change the governor address locally
    // no need to message remote routers; they should already have the same domain set and governor = bytes32(0)
    if (_isLocalGovernor) {
      return;
    }
    // format transfer governor message
    bytes memory _transferGovernorMessage = GovernanceMessage.formatTransferGovernor(
      _newDomain,
      TypeCasts.addressToBytes32(_newGovernor)
    );
    // send transfer governor message to all remote routers
    // note: this assumes that the Router is on the global GovernorDomain;
    // this causes a process error when relinquishing governorship
    // on a newly deployed domain which is not the GovernorDomain
    _sendToAllRemoteRouters(_transferGovernorMessage);
  }

  /**
   * @notice Transfer recovery manager role
   * @dev callable by the recoveryManager at any time to transfer the role
   * @param _newRecoveryManager The address of the new recovery manager
   */
  function transferRecoveryManager(address _newRecoveryManager) external onlyRecoveryManager {
    emit TransferRecoveryManager(recoveryManager, _newRecoveryManager);
    recoveryManager = _newRecoveryManager;
  }

  /**
   * @notice Set the router address for a given domain and
   * dispatch the change to all remote routers
   * @param _domain The domain
   * @param _router The address of the new router
   */
  function setRouterGlobal(uint32 _domain, bytes32 _router) external onlyGovernor onlyNotInRecovery {
    _setRouterGlobal(_domain, _router);
  }

  function _setRouterGlobal(uint32 _domain, bytes32 _router) internal {
    Home _home = Home(xAppConnectionManager.home());
    // Set up the call for use in the loop.
    // Because each domain's governance router may be different, we cannot
    // serialize the `Call` once and then reuse it. We have to re-serialize
    // the call, adjusting its `to` value on each step of the loop.
    GovernanceMessage.Call[] memory _calls = new GovernanceMessage.Call[](1);
    _calls[0].data = abi.encodeWithSignature("setRouterLocal(uint32,bytes32)", _domain, _router);
    for (uint256 i = 0; i < domains.length; i++) {
      uint32 _destination = domains[i];
      if (_destination != uint32(0)) {
        // set to, and dispatch
        bytes32 _recipient = routers[_destination];
        _calls[0].to = _recipient;
        bytes memory _msg = GovernanceMessage.formatBatch(_calls);
        _home.dispatch(_destination, _recipient, _msg);
      }
    }
    // set the router locally
    _setRouter(_domain, _router);
  }

  /**
   * @notice Set the router address *locally only*
   * @dev For use in deploy to setup the router mapping locally
   * @param _domain The domain
   * @param _router The new router
   */
  function setRouterLocal(uint32 _domain, bytes32 _router) external onlyGovernorOrRecoveryManager {
    // set the router locally
    _setRouter(_domain, _router);
  }

  /**
   * @notice Set the address of the XAppConnectionManager
   * @dev Domain/address validation helper
   * @param _xAppConnectionManager The address of the new xAppConnectionManager
   */
  function setXAppConnectionManager(address _xAppConnectionManager) public onlyGovernorOrRecoveryManager {
    xAppConnectionManager = XAppConnectionManager(_xAppConnectionManager);
  }

  /**
   * @notice Initiate the recovery timelock
   * @dev callable by the recovery manager
   */
  function initiateRecoveryTimelock() external onlyNotInRecovery onlyRecoveryManager {
    require(recoveryActiveAt == 0, "recovery already initiated");
    // set the time that recovery will be active
    recoveryActiveAt = block.timestamp.add(recoveryTimelock);
    emit InitiateRecovery(recoveryManager, recoveryActiveAt);
  }

  /**
   * @notice Exit recovery mode
   * @dev callable by the recovery manager to end recovery mode
   */
  function exitRecovery() external onlyRecoveryManager {
    require(recoveryActiveAt != 0, "recovery not initiated");
    delete recoveryActiveAt;
    emit ExitRecovery(recoveryManager);
  }

  // ============ Public Functions ============

  /**
   * @notice Check if the contract is in recovery mode currently
   * @return TRUE iff the contract is actively in recovery mode currently
   */
  function inRecovery() public view returns (bool) {
    uint256 _recoveryActiveAt = recoveryActiveAt;
    bool _recoveryInitiated = _recoveryActiveAt != 0;
    bool _recoveryActive = _recoveryActiveAt <= block.timestamp;
    return _recoveryInitiated && _recoveryActive;
  }

  // ============ Internal Functions ============

  /**
   * @notice Handle message dispatching calls locally
   * @dev We considered requiring the batch was not previously known.
   *      However, this would prevent us from ever processing identical
   *      batches, which seems desirable in some cases.
   *      As a result, we simply set it to pending.
   * @param _msg The message
   */
  function _handleBatch(bytes29 _msg) internal typeAssert(_msg, GovernanceMessage.Types.Batch) {
    bytes32 _batchHash = _msg.batchHash();
    // prevent accidental SSTORE and extra event if already pending
    if (inboundCallBatches[_batchHash] == BatchStatus.Pending) return;
    inboundCallBatches[_batchHash] = BatchStatus.Pending;
    emit BatchReceived(_batchHash);
  }

  /**
   * @notice execute a pending batch of messages
   */
  function executeCallBatch(GovernanceMessage.Call[] calldata _calls) external {
    bytes32 _batchHash = GovernanceMessage.getBatchHash(_calls);
    require(inboundCallBatches[_batchHash] == BatchStatus.Pending, "!batch pending");
    inboundCallBatches[_batchHash] = BatchStatus.Complete;
    for (uint256 i = 0; i < _calls.length; i++) {
      _callLocal(_calls[i]);
    }
    emit BatchExecuted(_batchHash);
  }

  /**
   * @notice Handle message transferring governorship to a new Governor
   * @param _msg The message
   */
  function _handleTransferGovernor(bytes29 _msg) internal typeAssert(_msg, GovernanceMessage.Types.TransferGovernor) {
    uint32 _newDomain = _msg.domain();
    address _newGovernor = TypeCasts.bytes32ToAddress(_msg.governor());
    bool _isLocalGovernor = _isLocalDomain(_newDomain);
    _transferGovernor(_newDomain, _newGovernor, _isLocalGovernor);
  }

  /**
   * @notice Dispatch message to all remote routers
   * @param _msg The message
   */
  function _sendToAllRemoteRouters(bytes memory _msg) internal {
    Home _home = Home(xAppConnectionManager.home());

    for (uint256 i = 0; i < domains.length; i++) {
      if (domains[i] != uint32(0)) {
        _home.dispatch(domains[i], routers[domains[i]], _msg);
      }
    }
  }

  /**
   * @notice Dispatch call locally
   * @param _call The call
   * @return _ret
   */
  function _callLocal(GovernanceMessage.Call memory _call) internal returns (bytes memory _ret) {
    address _toContract = TypeCasts.bytes32ToAddress(_call.to);
    // attempt to dispatch using low-level call
    bool _success;
    (_success, _ret) = _toContract.call(_call.data);
    // revert if the call failed
    require(_success, "call failed");
  }

  /**
   * @notice Transfer governorship within this contract's state
   * @param _newDomain The domain of the new governor
   * @param _newGovernor The address of the new governor
   * @param _isLocalGovernor True if the newDomain is the localDomain
   */
  function _transferGovernor(
    uint32 _newDomain,
    address _newGovernor,
    bool _isLocalGovernor
  ) internal {
    // require that the governor domain has a valid router
    if (!_isLocalGovernor) {
      _mustHaveRouter(_newDomain);
    }
    // Governor is 0x0 unless the governor is local
    address _newGov = _isLocalGovernor ? _newGovernor : address(0);
    // emit event before updating state variables
    emit TransferGovernor(governorDomain, _newDomain, governor, _newGov);
    // update state
    governorDomain = _newDomain;
    governor = _newGov;
  }

  /**
   * @notice Set the router for a given domain
   * @param _domain The domain
   * @param _newRouter The new router
   */
  function _setRouter(uint32 _domain, bytes32 _newRouter) internal {
    // ignore local domain in router mapping
    require(!_isLocalDomain(_domain), "can't set local router");
    // store previous router in memory
    bytes32 _previousRouter = routers[_domain];
    // if router is being removed,
    if (_newRouter == bytes32(0)) {
      // remove domain from array
      _removeDomain(_domain);
      // remove router from mapping
      delete routers[_domain];
    } else {
      // if router was not previously added,
      if (_previousRouter == bytes32(0)) {
        // add domain to array
        _addDomain(_domain);
      }
      // set router in mapping (add or change)
      routers[_domain] = _newRouter;
    }
    // emit event
    emit SetRouter(_domain, _previousRouter, _newRouter);
  }

  /**
   * @notice Add a domain that has a router
   * @param _domain The domain
   */
  function _addDomain(uint32 _domain) internal {
    domains.push(_domain);
  }

  /**
   * @notice Remove a domain from array
   * @param _domain The domain
   */
  function _removeDomain(uint32 _domain) internal {
    // find the index of the domain to remove & delete it from domains[]
    for (uint256 i = 0; i < domains.length; i++) {
      if (domains[i] == _domain) {
        delete domains[i];
        return;
      }
    }
  }

  /**
   * @notice Determine if a given domain and address is the Governor Router
   * @param _domain The domain
   * @param _address The address of the domain's router
   * @return _ret True if the given domain/address is the
   * Governor Router.
   */
  function _isGovernorRouter(uint32 _domain, bytes32 _address) internal view returns (bool) {
    return _domain == governorDomain && _address == routers[_domain];
  }

  /**
   * @notice Determine if a given domain is the local domain
   * @param _domain The domain
   * @return _ret - True if the given domain is the local domain
   */
  function _isLocalDomain(uint32 _domain) internal view returns (bool) {
    return _domain == localDomain;
  }

  /**
   * @notice Require that a domain has a router and returns the router
   * @param _domain The domain
   * @return _router - The domain's router
   */
  function _mustHaveRouter(uint32 _domain) internal view returns (bytes32 _router) {
    _router = routers[_domain];
    require(_router != bytes32(0), "!router");
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

// ============ External Imports ============
// import {TypedMemView} from "@summa-tx/memview-sol/contracts/TypedMemView.sol";
import {TypedMemView} from "../../libs/TypedMemView.sol";

library GovernanceMessage {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // Batch message characteristics
  // * 1 item - the type
  uint256 private constant BATCH_PREFIX_ITEMS = 1;
  // * type is 1 byte long
  uint256 private constant BATCH_PREFIX_LEN = 1;
  // * Length of a Batch message
  // * type + batch hash
  uint256 private constant BATCH_MESSAGE_LEN = 1 + 32;

  // Serialized Call[] characteristics
  // * 1 item - the type
  uint256 private constant CALLS_PREFIX_ITEMS = 1;
  // * type is 1 byte long
  uint256 private constant CALLS_PREFIX_LEN = 1;

  // Serialized Call characteristics
  // * Location of the data blob in a serialized call
  // * address + length
  uint256 private constant CALL_DATA_OFFSET = 32 + 4;

  // Transfer Governance message characteristics
  // * Length of a Transfer Governance message
  // * type + domain + address
  uint256 private constant TRANSFER_GOV_MESSAGE_LEN = 1 + 4 + 32;

  struct Call {
    bytes32 to;
    bytes data;
  }

  enum Types {
    Invalid, // 0
    Batch, // 1 - A Batch message
    TransferGovernor // 2 - A TransferGovernor message
  }

  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // Read the type of a message
  function messageType(bytes29 _view) internal pure returns (Types) {
    return Types(uint8(_view.typeOf()));
  }

  // Read the message identifer (first byte) of a message
  function identifier(bytes29 _view) internal pure returns (uint8) {
    return uint8(_view.indexUint(0, 1));
  }

  /*
   *   Message Type: BATCH
   *   struct Call {
   *       identifier,     // message ID -- 1 byte
   *       batchHash       // Hash of serialized calls (see below) -- 32 bytes
   *   }
   *
   *   struct Call {
   *       to,         // address to call -- 32 bytes
   *       dataLen,    // call data length -- 4 bytes,
   *       data        // call data -- 0+ bytes (variable)
   *   }
   *
   *   struct Calls
   *       numCalls,   // number of calls -- 1 byte
   *       calls[]     // serialized Call -- 0+ bytes
   *   }
   */

  // create a Batch message from a list of calls
  function formatBatch(Call[] memory _calls) internal view returns (bytes memory) {
    return abi.encodePacked(Types.Batch, getBatchHash(_calls));
  }

  // serialize a call to memory and return a reference
  function serializeCall(Call memory _call) internal pure returns (bytes29) {
    return abi.encodePacked(_call.to, uint32(_call.data.length), _call.data).ref(0);
  }

  function getBatchHash(Call[] memory _calls) internal view returns (bytes32) {
    // length prefix + 1 entry for each
    bytes29[] memory _encodedCalls = new bytes29[](_calls.length + CALLS_PREFIX_ITEMS);
    _encodedCalls[0] = abi.encodePacked(uint8(_calls.length)).ref(0);
    for (uint256 i = 0; i < _calls.length; i++) {
      _encodedCalls[i + CALLS_PREFIX_ITEMS] = serializeCall(_calls[i]);
    }
    return keccak256(TypedMemView.join(_encodedCalls));
  }

  function isValidBatch(bytes29 _view) internal pure returns (bool) {
    return identifier(_view) == uint8(Types.Batch) && _view.len() == BATCH_MESSAGE_LEN;
  }

  function isBatch(bytes29 _view) internal pure returns (bool) {
    return isValidBatch(_view) && messageType(_view) == Types.Batch;
  }

  function tryAsBatch(bytes29 _view) internal pure returns (bytes29) {
    if (isValidBatch(_view)) {
      return _view.castTo(uint40(Types.Batch));
    }
    return TypedMemView.nullView();
  }

  function mustBeBatch(bytes29 _view) internal pure returns (bytes29) {
    return tryAsBatch(_view).assertValid();
  }

  // Types.Batch
  function batchHash(bytes29 _view) internal pure returns (bytes32) {
    return _view.index(BATCH_PREFIX_LEN, 32);
  }

  /*
   *   Message Type: TRANSFER GOVERNOR
   *   struct TransferGovernor {
   *       identifier, // message ID -- 1 byte
   *       domain,     // domain of new governor -- 4 bytes
   *       addr        // address of new governor -- 32 bytes
   *   }
   */

  function formatTransferGovernor(uint32 _domain, bytes32 _governor) internal view returns (bytes memory _msg) {
    _msg = TypedMemView.clone(
      mustBeTransferGovernor(abi.encodePacked(Types.TransferGovernor, _domain, _governor).ref(0))
    );
  }

  function isValidTransferGovernor(bytes29 _view) internal pure returns (bool) {
    return identifier(_view) == uint8(Types.TransferGovernor) && _view.len() == TRANSFER_GOV_MESSAGE_LEN;
  }

  function isTransferGovernor(bytes29 _view) internal pure returns (bool) {
    return isValidTransferGovernor(_view) && messageType(_view) == Types.TransferGovernor;
  }

  function tryAsTransferGovernor(bytes29 _view) internal pure returns (bytes29) {
    if (isValidTransferGovernor(_view)) {
      return _view.castTo(uint40(Types.TransferGovernor));
    }
    return TypedMemView.nullView();
  }

  function mustBeTransferGovernor(bytes29 _view) internal pure returns (bytes29) {
    return tryAsTransferGovernor(_view).assertValid();
  }

  // Types.TransferGovernor
  function domain(bytes29 _view) internal pure returns (uint32) {
    return uint32(_view.indexUint(1, 4));
  }

  // Types.TransferGovernor
  function governor(bytes29 _view) internal pure returns (bytes32) {
    return _view.index(5, 32);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {IBridgeToken} from "../../interfaces/bridge/IBridgeToken.sol";
import {ERC20} from "./vendored/OZERC20.sol";
import {ConnextMessage} from "./ConnextMessage.sol";
// ============ External Imports ============
import {Version0} from "../../../nomad-core/contracts/Version0.sol";
import {TypeCasts} from "../../../nomad-core/contracts/XAppConnectionManager.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BridgeToken is Version0, IBridgeToken, OwnableUpgradeable, ERC20 {
  // ============ Immutables ============

  // Immutables used in EIP 712 structured data hashing & signing
  // https://eips.ethereum.org/EIPS/eip-712
  bytes32 public immutable _PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 private immutable _EIP712_STRUCTURED_DATA_VERSION = keccak256(bytes("1"));
  uint16 private immutable _EIP712_PREFIX_AND_VERSION = uint16(0x1901);

  // ============ Public Storage ============

  mapping(address => uint256) public nonces;
  /// @dev hash commitment to the name/symbol/decimals
  bytes32 public override detailsHash;

  // ============ Upgrade Gap ============

  uint256[48] private __GAP; // gap for upgrade safety

  // ============ Initializer ============

  function initialize() public override initializer {
    __Ownable_init();
  }

  // ============ Events ============

  event UpdateDetails(string indexed name, string indexed symbol, uint8 indexed decimals);

  // ============ External Functions ============

  /**
   * @notice Destroys `_amnt` tokens from `_from`, reducing the
   * total supply.
   * @dev Emits a {Transfer} event with `to` set to the zero address.
   * Requirements:
   * - `_from` cannot be the zero address.
   * - `_from` must have at least `_amnt` tokens.
   * @param _from The address from which to destroy the tokens
   * @param _amnt The amount of tokens to be destroyed
   */
  function burn(address _from, uint256 _amnt) external override onlyOwner {
    _burn(_from, _amnt);
  }

  /** @notice Creates `_amnt` tokens and assigns them to `_to`, increasing
   * the total supply.
   * @dev Emits a {Transfer} event with `from` set to the zero address.
   * Requirements:
   * - `to` cannot be the zero address.
   * @param _to The destination address
   * @param _amnt The amount of tokens to be minted
   */
  function mint(address _to, uint256 _amnt) external override onlyOwner {
    _mint(_to, _amnt);
  }

  /** @notice allows the owner to set the details hash commitment.
   * @param _detailsHash the new details hash.
   */
  function setDetailsHash(bytes32 _detailsHash) external override onlyOwner {
    if (detailsHash != _detailsHash) {
      detailsHash = _detailsHash;
    }
  }

  /**
   * @notice Set the details of a token
   * @param _newName The new name
   * @param _newSymbol The new symbol
   * @param _newDecimals The new decimals
   */
  function setDetails(
    string calldata _newName,
    string calldata _newSymbol,
    uint8 _newDecimals
  ) external override {
    bool _isFirstDetails = bytes(token.name).length == 0;
    // 0 case is the initial deploy. We allow the deploying registry to set
    // these once. After the first transfer is made, detailsHash will be
    // set, allowing anyone to supply correct name/symbols/decimals
    require(
      _isFirstDetails || ConnextMessage.formatDetailsHash(_newName, _newSymbol, _newDecimals) == detailsHash,
      "!committed details"
    );
    // careful with naming convention change here
    token.name = _newName;
    token.symbol = _newSymbol;
    token.decimals = _newDecimals;
    if (!_isFirstDetails) {
      emit UpdateDetails(_newName, _newSymbol, _newDecimals);
    }
  }

  /**
   * @notice Sets approval from owner to spender to value
   * as long as deadline has not passed
   * by submitting a valid signature from owner
   * Uses EIP 712 structured data hashing & signing
   * https://eips.ethereum.org/EIPS/eip-712
   * @param _owner The account setting approval & signing the message
   * @param _spender The account receiving approval to spend owner's tokens
   * @param _value The amount to set approval for
   * @param _deadline The timestamp before which the signature must be submitted
   * @param _v ECDSA signature v
   * @param _r ECDSA signature r
   * @param _s ECDSA signature s
   */
  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    require(block.timestamp <= _deadline, "ERC20Permit: expired deadline");
    require(_owner != address(0), "ERC20Permit: owner zero address");
    uint256 _nonce = nonces[_owner];
    bytes32 _hashStruct = keccak256(abi.encode(_PERMIT_TYPEHASH, _owner, _spender, _value, _nonce, _deadline));
    bytes32 _digest = keccak256(abi.encodePacked(_EIP712_PREFIX_AND_VERSION, domainSeparator(), _hashStruct));
    address _signer = ecrecover(_digest, _v, _r, _s);
    require(_signer == _owner, "ERC20Permit: invalid signature");
    nonces[_owner] = _nonce + 1;
    _approve(_owner, _spender, _value);
  }

  // ============ Public Functions ============

  /**
   * @dev silence the compiler being dumb
   */
  function balanceOf(address _account) public view override(IBridgeToken, ERC20) returns (uint256) {
    return ERC20.balanceOf(_account);
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view override returns (string memory) {
    return token.name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view override returns (string memory) {
    return token.symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view override returns (uint8) {
    return token.decimals;
  }

  /**
   * @dev This is ALWAYS calculated at runtime
   * because the token name may change
   */
  function domainSeparator() public view returns (bytes32) {
    uint256 _chainId;
    assembly {
      _chainId := chainid()
    }
    return
      keccak256(
        abi.encode(
          keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
          keccak256(bytes(token.name)),
          _EIP712_STRUCTURED_DATA_VERSION,
          _chainId,
          address(this)
        )
      );
  }

  // required for solidity inheritance
  function transferOwnership(address _newOwner) public override(IBridgeToken, OwnableUpgradeable) onlyOwner {
    OwnableUpgradeable.transferOwnership(_newOwner);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../interfaces/IExecutor.sol";

import "../lib/LibCrossDomainProperty.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract Counter {
  bool public shouldRevert;
  uint256 public count = 0;
  IExecutor public executor;

  constructor() {
    shouldRevert = false;
  }

  function setShouldRevert(bool value) public {
    shouldRevert = value;
  }

  function setExecutor(address _executor) public {
    executor = IExecutor(_executor);
  }

  function increment() public {
    require(!shouldRevert, "increment: shouldRevert is true");
    count += 1;
  }

  function incrementAndSend(
    address assetId,
    address recipient,
    uint256 amount
  ) public payable {
    if (assetId == address(0)) {
      require(msg.value == amount, "incrementAndSend: INVALID_ETH_AMOUNT");
    } else {
      require(msg.value == 0, "incrementAndSend: ETH_WITH_ERC");
      SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(assetId), msg.sender, address(this), amount);
    }
    increment();

    transferAsset(assetId, payable(recipient), amount);
  }

  function attack() public payable {
    require(msg.value >= 0.1 ether);
    executor.execute(
      bytes32(uint256(11111)),
      0.1 ether,
      payable(address(this)),
      address(0),
      LibCrossDomainProperty.EMPTY_BYTES,
      ""
    );
  }

  fallback() external payable {
    if (address(executor).balance >= 0.1 ether) {
      executor.execute(
        bytes32(uint256(11111)),
        0.1 ether,
        payable(address(this)),
        address(0),
        LibCrossDomainProperty.EMPTY_BYTES,
        ""
      );
    }
  }

  function transferAsset(
    address assetId,
    address payable recipient,
    uint256 amount
  ) internal {
    assetId == address(0)
      ? AddressUpgradeable.sendValue(recipient, amount)
      : SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(assetId), recipient, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ConnextProxyAdmin is ProxyAdmin {
  constructor(address owner) ProxyAdmin() {
    // We just need this for our hardhat tooling right now
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../interfaces/IERC20Minimal.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/* This token is ONLY useful for testing
 * Anybody can mint as many tokens as they like
 * Anybody can burn anyone else's tokens
 */
contract RevertableERC20 is ERC20 {
  bool public shouldRevert = false;

  constructor() ERC20("Revertable Token", "RVRT") {
    _mint(msg.sender, 1000000 ether);
  }

  function mint(address account, uint256 amount) external {
    require(!shouldRevert, "mint: SHOULD_REVERT");
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    require(!shouldRevert, "burn: SHOULD_REVERT");
    _burn(account, amount);
  }

  function transfer(address account, uint256 amount) public override returns (bool) {
    require(!shouldRevert, "transfer: SHOULD_REVERT");
    _transfer(msg.sender, account, amount);
    return true;
  }

  function balanceOf(address account) public view override returns (uint256) {
    require(!shouldRevert, "balanceOf: SHOULD_REVERT");
    return super.balanceOf(account);
  }

  function setShouldRevert(bool _shouldRevert) external {
    shouldRevert = _shouldRevert;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
  /// @notice Returns the balance of a token
  /// @param account The account for which to look up the number of tokens it has, i.e. its balance
  /// @return The number of tokens held by the account
  function balanceOf(address account) external view returns (uint256);

  /// @notice Transfers the amount of token from the `msg.sender` to the recipient
  /// @param recipient The account that will receive the amount transferred
  /// @param amount The number of tokens to send from the sender to the recipient
  /// @return Returns true for a successful transfer, false for an unsuccessful transfer
  function transfer(address recipient, uint256 amount) external returns (bool);

  /// @notice Returns the current allowance given to a spender by an owner
  /// @param owner The account of the token owner
  /// @param spender The account of the token spender
  /// @return The current allowance granted by `owner` to `spender`
  function allowance(address owner, address spender) external view returns (uint256);

  /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
  /// @param spender The account which will be allowed to spend a given amount of the owners tokens
  /// @param amount The amount of tokens allowed to be used by `spender`
  /// @return Returns true for a successful approval, false for unsuccessful
  function approve(address spender, uint256 amount) external returns (bool);

  /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
  /// @param sender The account from which the transfer will be initiated
  /// @param recipient The recipient of the transfer
  /// @param amount The amount of the transfer
  /// @return Returns true for a successful transfer, false for unsuccessful
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
  /// @param from The account from which the tokens were sent, i.e. the balance decreased
  /// @param to The account to which the tokens were sent, i.e. the balance increased
  /// @param value The amount of tokens that were transferred
  event Transfer(address indexed from, address indexed to, uint256 value);

  /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
  /// @param owner The account that approved spending of its tokens
  /// @param spender The account for which the spending allowance was modified
  /// @param value The new allowance from the owner to the spender
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../interfaces/IERC20Minimal.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/* This token is ONLY useful for testing
 * Anybody can mint as many tokens as they like
 * Anybody can burn anyone else's tokens
 */
contract FeeERC20 is ERC20 {
  uint256 public fee = 1;

  constructor() ERC20("Fee Token", "FEERC20") {
    _mint(msg.sender, 1000000 ether);
  }

  function setFee(uint256 _fee) external {
    fee = _fee;
  }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    _burn(account, amount);
  }

  function transfer(address account, uint256 amount) public override returns (bool) {
    uint256 toTransfer = amount - fee;
    _transfer(msg.sender, account, toTransfer);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    uint256 toTransfer = amount - fee;
    _burn(sender, fee);
    _transfer(sender, recipient, toTransfer);
    return true;
  }
}