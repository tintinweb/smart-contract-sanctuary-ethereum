/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

/// @title IOracle
/// @notice Read price of various token
interface IOracle {
    function getPrice(address token) external view returns (uint256);
}

enum Side {
    LONG,
    SHORT
}

interface IPositionManager {
    function increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeChanged,
        Side _side
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _desiredCollateralReduce,
        uint256 _sizeChanged,
        Side _side
    ) external;

    function liquidatePosition(
        address account,
        address collateralToken,
        address market,
        bool isLong
    ) external;

    function validateToken(
        address indexToken,
        Side side,
        address collateralToken
    ) external view returns (bool);
}

enum OrderType {
    INCREASE,
    DECREASE
}

/// @notice Order info
/// @dev The executor MUST save this info and call execute method whenever they think it fulfilled.
/// The approriate module will check for their condition and then execute, returning success or not
struct Order {
    IModule module;
    address owner;
    address indexToken;
    address collateralToken;
    uint256 sizeChanged;
    /// @notice when increase, collateralAmount is desired amount of collateral used as margin.
    /// When decrease, collateralAmount is value in USD of collateral user want to reduce from
    /// their position
    uint256 collateralAmount;
    uint256 executionFee;
    /// @notice To prevent front-running, order MUST be executed on next block
    uint256 submissionBlock;
    uint256 submissionTimestamp;
    // long or short
    Side side;
    OrderType orderType;
    // extra data for each order type
    bytes data;
}

/// @notice Order module, will parse orders and call to corresponding handler.
/// After execution complete, module will pass result to position manager to
/// update related position
/// Will be some kind of: StopLimitHandler, LimitHandler, MarketHandler...
interface IModule {
    function execute(IOracle oracle, Order memory order) external;

    function validate(Order memory order) external view;
}

interface IOrderBook {
    function placeOrder(
        IModule _module,
        address _indexToken,
        address _collateralToken,
        uint256 _side,
        OrderType _orderType,
        uint256 _sizeChanged,
        bytes calldata _data
    ) external payable;

    function executeOrder(bytes32 _key, address payable _feeTo) external;

    function executeOrders(bytes32[] calldata _key, address payable _feeTo) external;

    function cancelOrder(bytes32 _key) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

interface IPriceFeed {
    function postPrice(address token, uint price) external;
}

/**
 * @title PriceReporter
 * @notice Utility contract to call post prices and execute orders on a single transaction
 */
contract PriceReporter is Ownable {
    IPriceFeed private immutable oracle;
    IOrderBook private immutable orderBook;
    mapping(address => bool) public isReporter;
    address[] public reporters;

    constructor(address _oracle, address _orderBook) {
        require(_oracle != address(0), "invalid oracle");
        require(_orderBook != address(0), "invalid position manager");
        oracle = IPriceFeed(_oracle);
        orderBook = IOrderBook(_orderBook);
    }

    function postPriceAndExecuteOrders(address[] calldata tokens, uint[] calldata prices, bytes32[] calldata orders) external {
        require(isReporter[msg.sender], "unauthorized");
        require(tokens.length == prices.length, "invalid token prices data");
        for (uint256 i = 0; i < tokens.length; i++) {
            oracle.postPrice(tokens[i], prices[i]);
        }

        orderBook.executeOrders(orders, payable(msg.sender));
    }

    function addUpdater(address updater) external onlyOwner {
        require(!isReporter[updater], "PriceFeed::updaterAlreadyAdded");
        isReporter[updater] = true;
        reporters.push(updater);
    }

    function removeUpdater(address updater) external onlyOwner {
        require(isReporter[updater], "PriceFeed::updaterNotExists");
        isReporter[updater] = false;
        for (uint256 i = 0; i < reporters.length; i++) {
            if (reporters[i] == updater) {
                reporters[i] = reporters[reporters.length - 1];
                break;
            }
        }
        reporters.pop();
    }
}