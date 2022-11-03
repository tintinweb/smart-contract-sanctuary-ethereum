// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "Ownable.sol";
import "SafeMath.sol";
import "IERC20.sol";
import {ILibSoFee} from "ILibSoFee.sol";
import {ILibPrice} from "ILibPrice.sol";
import {IAggregatorV3Interface} from "IAggregatorV3Interface.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";

contract LibSoFeeWormholeV1 is ILibSoFee, ILibPrice, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // VARIABLES

    struct ChainlinkConfig {
        address router;
        // Countdown flag
        bool flag;
    }

    struct PriceConfig {
        ChainlinkConfig[] chainlink;
        // Update time interval
        uint256 interval;
    }

    struct PriceData {
        // The currnet price ratio of native coins
        uint256 currentPriceRatio;
        // Last update timestamp
        uint256 lastUpdateTimestamp;
    }

    uint256 public constant RAY = 1e27;

    uint256 public soFee;

    // Destination wormhole chain id => Oracle config
    mapping(uint16 => PriceConfig) priceConfig;
    mapping(uint16 => PriceData) priceData;

    //---------------------------------------------------------------------------
    // EVENT
    event UpdatePriceConfig(
        uint16 chainId,
        ChainlinkConfig[] chainlink,
        uint256 interval
    );
    event UpdatePriceInterval(uint16 chainId, uint256 interval);
    event UpdatePriceRatio(address sender, uint256 currentRatio);

    constructor(uint256 _soFee) {
        soFee = _soFee;
    }

    function setFee(uint256 _soFee) external onlyOwner {
        soFee = _soFee;
    }

    function setPriceConfig(
        uint16 _chainId,
        ChainlinkConfig[] memory _chainlink,
        uint256 _interval
    ) external onlyOwner {
        delete priceConfig[_chainId].chainlink;
        for (uint256 i = 0; i < _chainlink.length; i++) {
            priceConfig[_chainId].chainlink.push(
                ChainlinkConfig(_chainlink[i].router, _chainlink[i].flag)
            );
        }
        priceConfig[_chainId].interval = _interval;
        emit UpdatePriceConfig(_chainId, _chainlink, _interval);
    }

    function setPriceInterval(uint16 _chainId, uint256 _interval)
        external
        onlyOwner
    {
        priceConfig[_chainId].interval = _interval;
        emit UpdatePriceInterval(_chainId, _interval);
    }

    function getPriceRatioByChainlink(
        uint16 _chainId,
        PriceConfig memory _config
    ) external view returns (uint256) {
        uint256 _ratio = RAY;
        for (uint256 i = 0; i < _config.chainlink.length; i++) {
            IAggregatorV3Interface _aggregator = IAggregatorV3Interface(
                _config.chainlink[i].router
            );
            (, int256 _price, , , ) = _aggregator.latestRoundData();
            uint8 _decimals = _aggregator.decimals();
            if (_price <= 0) {
                return priceData[_chainId].currentPriceRatio;
            }
            if (_config.chainlink[i].flag) {
                _ratio = _ratio.mul(10**_decimals).div(uint256(_price));
            } else {
                _ratio = _ratio.mul(uint256(_price)).div(10**_decimals);
            }
        }
        return _ratio;
    }

    function getPriceRatio(uint16 _chainId)
        public
        view
        returns (uint256, bool)
    {
        PriceConfig memory _config = priceConfig[_chainId];
        if (_config.chainlink.length == 0) {
            return (priceData[_chainId].currentPriceRatio, false);
        }
        if (
            priceData[_chainId].lastUpdateTimestamp.add(_config.interval) >=
            block.timestamp
        ) {
            return (priceData[_chainId].currentPriceRatio, false);
        }
        try this.getPriceRatioByChainlink(_chainId, _config) returns (
            uint256 _result
        ) {
            return (_result, true);
        } catch {
            return (priceData[_chainId].currentPriceRatio, false);
        }
    }

    function updatePriceRatio(uint16 _chainId) external returns (uint256) {
        (uint256 _ratio, bool _flag) = getPriceRatio(_chainId);
        if (_flag) {
            priceData[_chainId].currentPriceRatio = _ratio;
            priceData[_chainId].lastUpdateTimestamp = block.timestamp;
            emit UpdatePriceRatio(msg.sender, _ratio);
        }
        return _ratio;
    }

    function setPriceRatio(uint16 _chainId, uint256 _ratio) external onlyOwner {
        priceData[_chainId].currentPriceRatio = _ratio;
        priceData[_chainId].lastUpdateTimestamp = block.timestamp;
        emit UpdatePriceRatio(msg.sender, _ratio);
    }

    function getRestoredAmount(uint256 _amountIn)
        external
        view
        override
        returns (uint256 r)
    {
        // calculate the amount to be restored
        r = _amountIn.mul(RAY).div((RAY - soFee));
        return r;
    }

    function getFees(uint256 _amountIn)
        external
        view
        override
        returns (uint256 s)
    {
        // calculate the so fee
        s = _amountIn.mul(soFee).div(RAY);
        return s;
    }

    function getTransferForGas() external view override returns (uint256) {
        return 0;
    }

    function getVersion() external pure override returns (string memory) {
        return "WormholeV1";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ILibSoFee {
    function getFees(uint256 _amount) external view returns (uint256 s);

    function getRestoredAmount(uint256 _amount)
        external
        view
        returns (uint256 r);

    function getTransferForGas() external view returns (uint256);

    function getVersion() external view returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ILibPrice {
    function getPriceRatio(uint16 _chainId)
        external
        view
        returns (uint256, bool);

    function updatePriceRatio(uint16 _chainId) external returns (uint256);

    function RAY() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAggregatorV3Interface {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title Reentrancy Guard
/// @author LI.FI (https://li.fi)
/// @notice Abstract contract to provide protection against reentrancy
abstract contract ReentrancyGuard {
    /// Storage ///

    bytes32 private constant NAMESPACE =
        hex"a65bb2f450488ab0858c00edc14abc5297769bf42adb48cfb77752890e8b697b";

    /// Types ///

    struct ReentrancyStorage {
        uint256 status;
    }

    /// Errors ///

    error ReentrancyError();

    /// Constants ///

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    /// Modifiers ///

    modifier nonReentrant() {
        ReentrancyStorage storage s = reentrancyStorage();
        if (s.status == _ENTERED) revert ReentrancyError();
        s.status = _ENTERED;
        _;
        s.status = _NOT_ENTERED;
    }

    /// Private Methods ///

    /// @dev fetch local storage
    function reentrancyStorage()
        private
        pure
        returns (ReentrancyStorage storage data)
    {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := position
        }
    }
}