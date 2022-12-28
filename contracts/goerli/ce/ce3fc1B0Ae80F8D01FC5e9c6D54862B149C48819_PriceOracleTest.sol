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
pragma solidity ^0.8.9;

interface IPriceOracle {
    event SetBasePrice(string indexed baseCurrency, uint256 basePrice);
    event SetDiscount(uint256 discount);

    function basePrice() external view returns (uint256);

    function baseCurrency() external view returns (string memory);

    function discount() external view returns (uint256);

    function config()
        external
        view
        returns (
            string memory baseCurrency,
            uint256 basePrice,
            uint256 discount
        );

    function currencyOf(string calldata currency_)
        external
        view
        returns (
            address token,
            uint8 decimals,
            address feed,
            bool enable
        );

    function price(
        string calldata name,
        uint256 registrationTime,
        uint256 expires,
        uint256 duration,
        string calldata currency
    )
        external
        view
        returns (
            uint256 amount,
            uint256 discount,
            uint256 baseAmount,
            uint256 baseDiscount
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IPriceOracle.sol";

contract PriceOracleTest is IPriceOracle, Ownable {
    struct Currency {
        AggregatorV3Interface feed;
        IERC20 token;
        uint8 decimals;
        bool enable;
    }

    uint256 public basePrice; // base price in usdt/day
    string public baseCurrency;
    uint256 public discount; // discount duration in day, for fst. year
    mapping(string => Currency) private _currencies;

    constructor(
        uint256 basePrice_,
        string memory baseCurrency_,
        uint256 discount_
    ) {
        basePrice = basePrice_;
        baseCurrency = baseCurrency_;
        discount = discount_;
    }

    function setBasePrice(string memory baseCurrency_, uint256 basePrice_)
        external
        onlyOwner
    {
        baseCurrency = baseCurrency_;
        basePrice = basePrice_;
        emit SetBasePrice(baseCurrency_, basePrice_);
    }

    function setDiscount(uint256 discount_) external onlyOwner {
        discount = discount_;
        emit SetDiscount(discount_);
    }

    function config()
        external
        view
        returns (
            string memory,
            uint256,
            uint256
        )
    {
        return (baseCurrency, basePrice, discount);
    }

    function _priceInUSDT(
        string calldata, /*name__*/
        uint256 registrationTime_,
        uint256 expires_,
        uint256 duration_ // in day
    ) internal view returns (uint256, uint256) {
        require(block.timestamp >= registrationTime_);

        uint256 duration = duration_;
        if (expires_ == 0) {
            if (duration_ >= discount) {
                duration = duration_ - discount; // discount for first mint and first year
            } else {
                duration = 0;
            }
        }

        uint256 span = registrationTime_ > 0
            ? (block.timestamp - registrationTime_)
            : 0;
        uint256 discountedPrice = basePrice;
        if (span <= 24 hours) {
            discountedPrice = basePrice / 2;
        } else if (span <= 1 weeks) {
            discountedPrice = (basePrice * 6) / 10;
        } else if (span <= 30 days) {
            discountedPrice = (basePrice * 7) / 10;
        }

        return (
            discountedPrice * duration,
            (basePrice - discountedPrice) *
                duration +
                basePrice *
                (duration_ - duration)
        );
    }

    function price(
        string calldata name_,
        uint256 registrationTime_,
        uint256 expires_,
        uint256 duration_,
        string calldata currency_
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 amount, uint256 discounted) = _priceInUSDT(
            name_,
            registrationTime_,
            expires_,
            duration_
        );

        if (bytes32(bytes(currency_)) == bytes32(bytes(baseCurrency))) {
            return (amount, discounted, 0, 0);
        }

        require(_currencies[currency_].enable, "price oracle required");
        (, int256 latestPrice, , , ) = _currencies[currency_]
            .feed
            .latestRoundData();
        require(latestPrice > 0, "price oracle error occurred");
        return (
            (amount *
                10**_currencies[currency_].decimals *
                10**_currencies[currency_].feed.decimals()) /
                (uint256(latestPrice) * 10**_currencies[baseCurrency].decimals),
            (discounted *
                10**_currencies[currency_].decimals *
                10**_currencies[currency_].feed.decimals()) /
                (uint256(latestPrice) * 10**_currencies[baseCurrency].decimals),
            amount,
            discounted
        );
    }

    function currencyOf(string calldata currency_)
        external
        view
        returns (
            address,
            uint8,
            address,
            bool
        )
    {
        Currency memory currency = _currencies[currency_];
        return (
            address(currency.token),
            currency.decimals,
            address(currency.feed),
            currency.enable
        );
    }

    function addCurrency(
        string memory currency_,
        address token_,
        uint8 decimals_,
        address feed_
    ) external onlyOwner {
        _currencies[currency_] = Currency({
            enable: true,
            token: IERC20(token_),
            decimals: decimals_,
            feed: AggregatorV3Interface(feed_)
        });
    }

    function removeCurrency(string memory currency_) external onlyOwner {
        _currencies[currency_].enable = false;
    }
}