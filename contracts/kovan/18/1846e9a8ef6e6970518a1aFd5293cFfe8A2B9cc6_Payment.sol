// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

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

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

contract Payment is Initializable, OwnableUpgradeable, PausableUpgradeable {
    enum PaymentType {
        PROVIDER_NODE_FEE_MONTHLY,
        PREMIUM_FEE_MONTHLY,
        ENTERPRISE_FEE_MONTHLY
    }

    address public treasury;
    address public XCNToken;
    address public USDTToken;
    address public usdtEthPriceFeed;
    address public usdtXcnPriceFeed;
    // type + token => amount
    mapping(PaymentType => uint256) public paymentAmountInUSDT;
    mapping(PaymentType => mapping(address => uint256)) public discount; // unit 1e18
    uint256 public constant HUNDRED_PERCENT = 1e18;

    event Payment(
        address payer,
        address token,
        uint256 amount,
        uint256 discount,
        PaymentType paymentType,
        uint256 paymentId
    );
    event SetPaymentAmount(PaymentType paymentType, uint256 amount);
    event SetDiscount(PaymentType paymentType, address token, uint256 discount);
    event ChangeTreasury(address treasury);
    event SetOracle(address usdtEthPriceFeed, address usdtXcnPriceFeed);

    function initialize(
        address _treasury,
        address _XCN,
        address _usdtEthPriceFeed,
        address _usdtXcnPriceFeed
    ) external initializer {
        __Ownable_init();
        treasury = _treasury;
        XCNToken = _XCN;
        usdtEthPriceFeed = _usdtEthPriceFeed;
        usdtXcnPriceFeed = _usdtXcnPriceFeed;
    }

    /**
     * @notice Pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setOracle(address _usdtEthPriceFeed, address _usdtXcnPriceFeed) external onlyOwner {
        usdtEthPriceFeed = _usdtEthPriceFeed;
        usdtXcnPriceFeed = _usdtXcnPriceFeed;

        emit SetOracle(_usdtEthPriceFeed, _usdtXcnPriceFeed);
    }

    function setPaymentAmount(PaymentType _type, uint256 _amount) external onlyOwner {
        paymentAmountInUSDT[_type] = _amount;
        emit SetPaymentAmount(_type, _amount);
    }

    function setDiscount(
        PaymentType _type,
        address _token,
        uint256 _discount
    ) external onlyOwner {
        discount[_type][_token] = _discount;
        emit SetDiscount(_type, _token, _discount);
    }

    function getPaymentAmount(PaymentType _type) external returns (uint256) {
        return paymentAmountInUSDT[_type];
    }

    function getDiscountAmount(PaymentType _type, address _token) external returns (uint256) {
        return discount[_type][_token];
    }

    function pay(
        PaymentType _type,
        address _token,
        uint256 _paymentId
    ) external payable {
        if (_token == address(0)) {
            uint256 usdtAmount = paymentAmountInUSDT[_type] -
                (paymentAmountInUSDT[_type] * discount[_type][address(0)]) /
                HUNDRED_PERCENT;
            uint256 requireETHAmount = getTokenAmountFromUSDT(address(0), usdtAmount);

            require(msg.value >= requireETHAmount, "Payment: not valid pay amount");

            // cashback exceeds amount to sender
            uint256 exceedETH = msg.value - requireETHAmount;
            if (exceedETH > 0) {
                payable(msg.sender).transfer(exceedETH);
            }
            emit Payment(msg.sender, _token, requireETHAmount, discount[_type][address(0)], _type, _paymentId);
        } else {
            uint256 usdtAmount = paymentAmountInUSDT[_type] -
                (paymentAmountInUSDT[_type] * discount[_type][_token]) /
                HUNDRED_PERCENT;
            uint256 requireTokenAmount = getTokenAmountFromUSDT(address(0), usdtAmount);

            IERC20(_token).transferFrom(msg.sender, treasury, requireTokenAmount);
            emit Payment(msg.sender, _token, requireTokenAmount, discount[_type][_token], _type, _paymentId);
        }
    }

    function changeTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit ChangeTreasury(_treasury);
    }

    function getTokenAmountFromUSDT(address _token, uint256 _usdtAmount) public view returns (uint256) {
        (uint256 price, uint8 decimals) = getLatestPrice(_token);
        uint8 usdtDecimals = IERC20Decimals(USDTToken).decimals();
        uint8 tokenDecimals = IERC20Decimals(_token).decimals();
        return (_usdtAmount * price * tokenDecimals) / (decimals * usdtDecimals);
    }

    function getLatestPrice(address _token)
        public
        view
        returns (
            uint256,
            uint8 /* decimals */
        )
    {
        address priceFeed;

        if (_token == address(0)) {
            priceFeed = usdtEthPriceFeed;
        } else if (_token == XCNToken) {
            priceFeed = usdtXcnPriceFeed;
        } else if (_token == USDTToken) {
            return (1, 1);
        } else {
            revert("Payment: invalid token");
        }

        (, int256 price, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        uint8 decimals = AggregatorV3Interface(priceFeed).decimals();
        return (uint256(price), decimals);
    }
}