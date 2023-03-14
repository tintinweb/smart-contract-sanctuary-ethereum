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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IHODL.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract HODL is IHODL, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    // mapping exclude from fee
    mapping (address => bool) private _isExcludedFromFee;

    // mapping exclude from reflected reward
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**8 * 10**18;                      // Total Supply: 100M
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "DEMOHODL2";
    string private _symbol = "DEMOHODL2";
    uint8 private _decimals = 18;
    uint256 private denomiator = 10000;                             // Denominator to calculate percent

    // Fees
    // REWARDS & BONUSES
    uint256 public feeRewardNBonusSell = 30;
    uint256 public feeRewardNBonusBuy = 9;
    uint256 public feeRewardNBonusTransfer = 3;
    uint256 public feeRewardNBonusNFT = 300;
    // Airdrop
    uint256 public feeAirDropSell = 30;
    uint256 public feeAirDropBuy = 9;
    uint256 public feeAirDropTransfer = 3;
    uint256 public feeAirDropNFT = 300;
    // Liquidity
    uint256 public feeLiquiditySell = 100;
    uint256 public feeLiquidityBuy = 30;
    uint256 public feeLiquidityTransfer = 10;
    uint256 public feeLiquidityNFT = 600;
    // PRIVATE / PUBLIC OFFERING
    uint256 public feePrivateNPublicOfferingSell = 10;
    uint256 public feePrivateNPublicOfferingBuy = 3;
    uint256 public feePrivateNPublicOfferingTransfer = 1;
    uint256 public feePrivateNPublicOfferingNFT = 100;
    // EQUITY HODLINGS
    uint256 public feeEquityHoldingSell = 100;
    uint256 public feeEquityHoldingBuy = 30;
    uint256 public feeEquityHoldingTransfer = 10;
    uint256 public feeEquityHoldingNFT = 3200;
    // GENERAL OPERATING FUND
    uint256 public feeGeneralOperatingSell = 50;
    uint256 public feeGeneralOperatingBuy = 15;
    uint256 public feeGeneralOperatingTransfer = 5;
    uint256 public feeGeneralOperatingNFT = 600;
    // GRANTS & GIFTS
    uint256 public feeGrantNGiftSell = 30;
    uint256 public feeGrantNGiftBuy = 9;
    uint256 public feeGrantNGiftTransfer = 3;
    uint256 public feeGrantNGiftNFT = 300;
    // IN-FLO & OUT-FLO
    uint256 public feeInOutFloSell = 10;
    uint256 public feeInOutFloBuy = 3;
    uint256 public feeInOutFloTransfer = 1;
    uint256 public feeInOutFloNFT = 800;
    // HODL TOKEN HOLDERS(Reflection)
    uint256 public feeReflectionSell = 200;
    uint256 public feeReflectionBuy = 60;
    uint256 public feeReflectionTransfer = 20;
    uint256 public feeReflectionNFT = 2200;
    // FOUNDATION
    uint256 public feeFoundationSell = 80;
    uint256 public feeFoundationBuy = 24;
    uint256 public feeFoundationTransfer = 8;
    uint256 public feeFoundationNFT = 800;
    // Burn
    uint256 public feeBurnSell = 200;
    uint256 public feeBurnBuy = 60;
    uint256 public feeBurnTransfer = 20;
    // Founders
    uint256 public feeFounderSell = 100;
    uint256 public feeFounderBuy = 30;
    uint256 public feeFounderTransfer = 10;
    // Team Members
    uint256 public feeTeamSell = 10;
    uint256 public feeTeamBuy = 3;
    uint256 public feeTeamTransfer = 1;
    // Equity Partners
    uint256 public feeEquityPartnerSell = 50;
    uint256 public feeEquityPartnerBuy = 15;
    uint256 public feeEquityPartnerTransfer = 5;
    uint256 public feeEquityPartnerNFT = 800;

    uint256 private _feeRewardNBonus = 0;
    uint256 private _feeAirDrop = 0;
    uint256 private _feeLiquidity = 0;
    uint256 private _feePrivateNPublicOffering = 0;
    uint256 private _feeEquityHolding = 0;
    uint256 private _feeGeneralOperating = 0;
    uint256 private _feeGrantNGift = 0;
    uint256 private _feeInOutFlo = 0;
    uint256 private _feeFoundation = 0;
    uint256 private _feeReflection = 0;
    uint256 private _feeBurn = 0;
    uint256 private _feeFounder = 0;
    uint256 private _feeTeam = 0;
    uint256 private _feeEquityPartner = 0;

    uint256 private _totalFeeWithoutReflection = 0;

    // Treasury and splitter addresses;
    address public addrRewardNBonus = 0xC41bcA4B249CBa41d3F8e9352A21b8b08ED33d45;
    address public addrAirDrop = 0x07aaC40c0F9544f6fe9B6cFb37843dB0D473f960;
    address public addrLiquidity = 0xfBEBDec333917d60DEfb5DDb15c28B37307861Ad;
    address public addrPrivateNPublicOffering = 0x934388d901388B03394D44B59d028a1aaC3A767b;
    address public addrEquityHolding = 0xD3b242D93a8856749c0195C192DdeBe096F93298;
    address public addrGeneralOperating = 0xF581299845bbcF7B7dB09E5aC676d441b6e43397;
    address public addrGrantNGift = 0x6d757a5bCD754c06b3c421D2ee88615c874463df;
    address public addrInOutFlo = 0x027Ef54F9846dF4d5eFbcBc918cc77bA148D1485;
    address public addrFoundation = 0x3f5E8f53F1FDcCAd8fa797eA6B4CED29872d9010;
    address public addrBurn = address(0);
    address public addrFounder = 0xBB5d9D66CC3FcD4f2e10Eb8eB4A4C61b8e9CB2e2;
    address public addrTeam = 0x641B759EE8c2669A84c0fF88D21bC22C82933499;
    address public addrEquityPartner = 0x48be95B6FA64B19E28501Bd3959755df069b549e;

    uint256 public _maxTxAmount = 10**8 * 10**18;
    bool public tradeEnabled = false;
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    mapping (address => bool) private automatedMarketMakerPairs;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    mapping (address => bool) private _nftSplitters;

    /**
     * @dev Throws if caller is not splitter.
     */
    modifier onlySplitters() {
        require(_nftSplitters[msg.sender], "no permission to call this function");
        _;
    }

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // Burn address is exclued from reflected reward
        excludeFromReward(addrBurn);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) public override returns (bool) {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
        return true;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 currentRate = _getRate();
            uint256 rAmount = tAmount.mul(currentRate);
            return rAmount;
        } else {
            (, uint256 tFee, uint256 tReward) = _getTValues(tAmount);
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tReward);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }

    function setTradingEnabled(bool _enabled) external onlyOwner() {
        tradeEnabled = _enabled;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function setRewardNBonusWallet(address wallet) public onlyOwner {
        addrRewardNBonus = wallet;
    }

    function setAirDropWallet(address wallet) public onlyOwner {
        addrAirDrop = wallet;
    }

    function setLiquidityWallet(address wallet) public onlyOwner {
        addrLiquidity = wallet;
    }

    function setPrivateNPublicOfferingWallet(address wallet) public onlyOwner {
        addrPrivateNPublicOffering = wallet;
    }

    function setEquityHoldingWallet(address wallet) public onlyOwner {
        addrEquityHolding = wallet;
    }

    function setGeneralOperatingWallet(address wallet) public onlyOwner {
        addrGeneralOperating = wallet;
    }

    function setGrantNGiftWallet(address wallet) public onlyOwner {
        addrGrantNGift = wallet;
    }

    function setInOutFloWallet(address wallet) public onlyOwner {
        addrInOutFlo = wallet;
    }

    function setFoundationWallet(address wallet) public onlyOwner {
        addrFoundation = wallet;
    }

    function setFounderWallet(address wallet) public onlyOwner {
        addrFounder = wallet;
    }

    function setTeamWallet(address wallet) public onlyOwner {
        addrTeam = wallet;
    }

    function setEquityPartnerWallet(address wallet) public onlyOwner {
        addrEquityPartner = wallet;
    }
    
    // to recieve ETH and move it to Equity Holding Treasury
    receive() external payable {
        require(msg.value > 0, 'No amount');
        Address.sendValue(payable(addrEquityHolding), msg.value);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tReflection = calculateReflectionFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tReflection);
        return (tTransferAmount, tFee, tReflection);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tReflection) private view returns (uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rReflection);
        return (rAmount, rTransferAmount, rReflection);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner()) {
            // Check max amount to sell
            if (automatedMarketMakerPairs[to]) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }

            // Check tradable
            if (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]) {
                require(tradeEnabled, "Trade is not enabled yet");
            }
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        // Set fee percent for buy and sell
        if (automatedMarketMakerPairs[to]) { // sell
            setSellFees();
        }
        else if (automatedMarketMakerPairs[from]) { // buy
            setBuyFees();
        }
        else { // Transfer
            setTransferFees();
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        if (!takeFee) {
            removeAllFee();
        }

        if (to == address(this)) {
            // transfer amount to Equity Holding
            _tokenTransfer(from, addrEquityHolding, amount);
        }
        else {
            // transfer amount
            _tokenTransfer(from,to,amount);
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tReflection) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValues(tAmount, tFee, tReflection);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (_totalFeeWithoutReflection > 0) {
            uint256 currentRate = _getRate();
            _takeTaxes(tAmount, currentRate);
        }

        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tReflection) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValues(tAmount, tFee, tReflection);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        
        if (_totalFeeWithoutReflection > 0) {
            uint256 currentRate = _getRate();
            _takeTaxes(tAmount, currentRate);
        }

        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tReflection) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValues(tAmount, tFee, tReflection);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        if (_totalFeeWithoutReflection > 0) {
            uint256 currentRate = _getRate();
            _takeTaxes(tAmount, currentRate);
        }

        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tReflection) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValues(tAmount, tFee, tReflection);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        
        if (_totalFeeWithoutReflection > 0) {
            uint256 currentRate = _getRate();
            _takeTaxes(tAmount, currentRate);
        }

        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTaxes(uint256 tAmount, uint256 currentRate) private {
        _takeRewardNBonus(tAmount, currentRate);
        _takeAirDrop(tAmount, currentRate);
        _takeLiquidity(tAmount, currentRate);
        _takePrivateNPublicOffering(tAmount, currentRate);
        _takeEquityHolding(tAmount, currentRate);
        _takeGeneralOperating(tAmount, currentRate);
        _takeGrantNGift(tAmount, currentRate);
        _takeInOutFlo(tAmount, currentRate);
        _takeFoundation(tAmount, currentRate);
        _takeBurn(tAmount, currentRate);
        _takeFounder(tAmount, currentRate);
        _takeTeam(tAmount, currentRate);
        _takeEquityPartner(tAmount, currentRate);
    }

    function _takeRewardNBonus(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeRewardNBonus);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrRewardNBonus] = _rOwned[addrRewardNBonus].add(rFee);
        if(_isExcluded[addrRewardNBonus])
            _tOwned[addrRewardNBonus] = _tOwned[addrRewardNBonus].add(tFee);

        emit Transfer(address(this), addrRewardNBonus, tFee);
    }

    function _takeAirDrop(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeAirDrop);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrAirDrop] = _rOwned[addrAirDrop].add(rFee);
        if(_isExcluded[addrAirDrop])
            _tOwned[addrAirDrop] = _tOwned[addrAirDrop].add(tFee);

        emit Transfer(address(this), addrAirDrop, tFee);
    }

    function _takeLiquidity(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeLiquidity);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrLiquidity] = _rOwned[addrLiquidity].add(rFee);
        if(_isExcluded[addrLiquidity])
            _tOwned[addrLiquidity] = _tOwned[addrLiquidity].add(tFee);

        emit Transfer(address(this), addrLiquidity, tFee);
    }

    function _takePrivateNPublicOffering(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feePrivateNPublicOffering);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrPrivateNPublicOffering] = _rOwned[addrPrivateNPublicOffering].add(rFee);
        if(_isExcluded[addrPrivateNPublicOffering])
            _tOwned[addrPrivateNPublicOffering] = _tOwned[addrPrivateNPublicOffering].add(tFee);

        emit Transfer(address(this), addrPrivateNPublicOffering, tFee);
    }

    function _takeEquityHolding(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeEquityHolding);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrEquityHolding] = _rOwned[addrEquityHolding].add(rFee);
        if(_isExcluded[addrEquityHolding])
            _tOwned[addrEquityHolding] = _tOwned[addrEquityHolding].add(tFee);

        emit Transfer(address(this), addrEquityHolding, tFee);
    }

    function _takeGeneralOperating(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeGeneralOperating);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrGeneralOperating] = _rOwned[addrGeneralOperating].add(rFee);
        if(_isExcluded[addrGeneralOperating])
            _tOwned[addrGeneralOperating] = _tOwned[addrGeneralOperating].add(tFee);

        emit Transfer(address(this), addrGeneralOperating, tFee);
    }

    function _takeGrantNGift(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeGrantNGift);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrGrantNGift] = _rOwned[addrGrantNGift].add(rFee);
        if(_isExcluded[addrGrantNGift])
            _tOwned[addrGrantNGift] = _tOwned[addrGrantNGift].add(tFee);

        emit Transfer(address(this), addrGrantNGift, tFee);
    }

    function _takeInOutFlo(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeInOutFlo);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrInOutFlo] = _rOwned[addrInOutFlo].add(rFee);
        if(_isExcluded[addrInOutFlo])
            _tOwned[addrInOutFlo] = _tOwned[addrInOutFlo].add(tFee);

        emit Transfer(address(this), addrInOutFlo, tFee);
    }

    function _takeFoundation(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeFoundation);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrFoundation] = _rOwned[addrFoundation].add(rFee);
        if(_isExcluded[addrFoundation])
            _tOwned[addrFoundation] = _tOwned[addrFoundation].add(tFee);

        emit Transfer(address(this), addrFoundation, tFee);
    }

    function _takeFounder(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeFounder);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrFounder] = _rOwned[addrFounder].add(rFee);
        if(_isExcluded[addrFounder])
            _tOwned[addrFounder] = _tOwned[addrFounder].add(tFee);

        emit Transfer(address(this), addrFounder, tFee);
    }

    function _takeTeam(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeTeam);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrTeam] = _rOwned[addrTeam].add(rFee);
        if(_isExcluded[addrTeam])
            _tOwned[addrTeam] = _tOwned[addrTeam].add(tFee);

        emit Transfer(address(this), addrTeam, tFee);
    }

    function _takeEquityPartner(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeEquityPartner);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrEquityPartner] = _rOwned[addrEquityPartner].add(rFee);
        if(_isExcluded[addrEquityPartner])
            _tOwned[addrEquityPartner] = _tOwned[addrEquityPartner].add(tFee);

        emit Transfer(address(this), addrEquityPartner, tFee);
    }

    function _takeBurn(uint256 _amount, uint256 _rate) private {
        uint256 tFee = calculateFee(_amount, _feeBurn);
        uint256 rFee = tFee.mul(_rate);

        _rOwned[addrBurn] = _rOwned[addrBurn].add(rFee);
        if(_isExcluded[addrBurn])
            _tOwned[addrBurn] = _tOwned[addrBurn].add(tFee);

        emit Transfer(address(this), addrBurn, tFee);
    }

    function calculateFee(uint256 _amount, uint256 _fee) private view returns (uint256) {
        return _amount.mul(_fee).div(
            denomiator
        );
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_totalFeeWithoutReflection).div(
            denomiator
        );
    }

    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_feeReflection).div(
            denomiator
        );
    }

    function setSellFees() private {
        _feeRewardNBonus = feeRewardNBonusSell;
        _feeAirDrop = feeAirDropSell;
        _feeLiquidity = feeLiquiditySell;
        _feePrivateNPublicOffering = feePrivateNPublicOfferingSell;
        _feeEquityHolding = feeEquityHoldingSell;
        _feeGeneralOperating = feeGeneralOperatingSell;
        _feeGrantNGift = feeGrantNGiftSell;
        _feeInOutFlo = feeInOutFloSell;
        _feeFoundation = feeFoundationSell;
        _feeReflection = feeReflectionSell;
        _feeBurn = feeBurnSell;
        _feeFounder = feeFounderSell;
        _feeTeam = feeTeamSell;
        _feeEquityPartner = feeEquityPartnerSell;

        _totalFeeWithoutReflection = _feeRewardNBonus + _feeAirDrop + _feeLiquidity + _feePrivateNPublicOffering + _feeEquityHolding + _feeGeneralOperating + _feeGrantNGift + _feeInOutFlo + _feeFoundation + _feeBurn + _feeFounder + _feeTeam + _feeEquityPartner;
    }

    function setBuyFees() private {
        _feeRewardNBonus = feeRewardNBonusBuy;
        _feeAirDrop = feeAirDropBuy;
        _feeLiquidity = feeLiquidityBuy;
        _feePrivateNPublicOffering = feePrivateNPublicOfferingBuy;
        _feeEquityHolding = feeEquityHoldingBuy;
        _feeGeneralOperating = feeGeneralOperatingBuy;
        _feeGrantNGift = feeGrantNGiftBuy;
        _feeInOutFlo = feeInOutFloBuy;
        _feeFoundation = feeFoundationBuy;
        _feeReflection = feeReflectionBuy;
        _feeBurn = feeBurnBuy;
        _feeFounder = feeFounderBuy;
        _feeTeam = feeTeamBuy;
        _feeEquityPartner = feeEquityPartnerBuy;

        _totalFeeWithoutReflection = _feeRewardNBonus + _feeAirDrop + _feeLiquidity + _feePrivateNPublicOffering + _feeEquityHolding + _feeGeneralOperating + _feeGrantNGift + _feeInOutFlo + _feeFoundation + _feeBurn + _feeFounder + _feeTeam + _feeEquityPartner;
    }

    function setTransferFees() private {
        _feeRewardNBonus = feeRewardNBonusTransfer;
        _feeAirDrop = feeAirDropTransfer;
        _feeLiquidity = feeLiquidityTransfer;
        _feePrivateNPublicOffering = feePrivateNPublicOfferingTransfer;
        _feeEquityHolding = feeEquityHoldingTransfer;
        _feeGeneralOperating = feeGeneralOperatingTransfer;
        _feeGrantNGift = feeGrantNGiftTransfer;
        _feeInOutFlo = feeInOutFloTransfer;
        _feeFoundation = feeFoundationTransfer;
        _feeReflection = feeReflectionTransfer;
        _feeBurn = feeBurnTransfer;
        _feeFounder = feeFounderTransfer;
        _feeTeam = feeTeamTransfer;
        _feeEquityPartner = feeEquityPartnerTransfer;

        _totalFeeWithoutReflection = _feeRewardNBonus + _feeAirDrop + _feeLiquidity + _feePrivateNPublicOffering + _feeEquityHolding + _feeGeneralOperating + _feeGrantNGift + _feeInOutFlo + _feeFoundation + _feeBurn + _feeFounder + _feeTeam + _feeEquityPartner;
    }

    function setNFTFees() private {
        _feeRewardNBonus = feeRewardNBonusNFT;
        _feeAirDrop = feeAirDropNFT;
        _feeLiquidity = feeLiquidityNFT;
        _feePrivateNPublicOffering = feePrivateNPublicOfferingNFT;
        _feeEquityHolding = feeEquityHoldingNFT;
        _feeGeneralOperating = feeGeneralOperatingNFT;
        _feeGrantNGift = feeGrantNGiftNFT;
        _feeInOutFlo = feeInOutFloNFT;
        _feeFoundation = feeFoundationNFT;
        _feeReflection = feeReflectionNFT;
        _feeBurn = 0;
        _feeFounder = 0;
        _feeTeam = 0;
        _feeEquityPartner = feeEquityPartnerNFT;

        _totalFeeWithoutReflection = _feeRewardNBonus + _feeAirDrop + _feeLiquidity + _feePrivateNPublicOffering + _feeEquityHolding + _feeGeneralOperating + _feeGrantNGift + _feeInOutFlo + _feeFoundation + _feeEquityPartner;
    }

    function removeAllFee() private {
        _feeRewardNBonus = 0;
        _feeAirDrop = 0;
        _feeLiquidity = 0;
        _feePrivateNPublicOffering = 0;
        _feeEquityHolding = 0;
        _feeGeneralOperating = 0;
        _feeGrantNGift = 0;
        _feeInOutFlo = 0;
        _feeFoundation = 0;
        _feeReflection = 0;
        _feeBurn = 0;
        _feeFounder = 0;
        _feeTeam = 0;
        _feeEquityPartner = 0;

        _totalFeeWithoutReflection = 0;
    }

    function setNFTSplitters(address splitter, bool value) external onlyOwner {
        _nftSplitters[splitter] = value;
    }

    function splitNFTFee(uint256 amount) external onlySplitters returns (bool) {
        setNFTFees();
        _transfer(msg.sender, address(this), amount);
        return true;
    }

    function withdrawToken(uint256 _amount) external onlyOwner {
        require(_amount <= balanceOf(address(this)), "No enough balance");

        _transfer(address(this), owner(), _amount);
    }

    function withdrawEth(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "No enough balance");

        (bool success, ) = owner().call{value: _amount}("");

        require(success, "Unable to send eth");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IHODL {
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

    /**
     * @dev reflect `tAmount` tokens to token holders
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     */
    function reflect(
        uint256 tAmount
    ) external returns (bool);

    /**
     * @dev split NFT fee to escrow wallets and splitters
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     */
    function splitNFTFee(
        uint256 tAmount
    ) external returns (bool);
}