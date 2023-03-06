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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interface/IERC20.sol";
import "./DCAOrderSystemCore.sol";

contract DCAOrderSystemBeginner is DCAOrderSystemCore {
    using EnumerableSet for EnumerableSet.UintSet;
    
    constructor(uint256 _deadline, address _adminWallet) {
        deadline = _deadline;
        adminWallet = _adminWallet;
    }

    function cancelOrder(uint256 _orderId) external {
        require(msg.sender == orderList[_orderId].dcaPlanner, "You are not the planner of this order!");
        Order memory order = orderList[_orderId];
        delete orderBook[order.dcaAutopilot];
        orderList[_orderId].status = OrderStatus.Canceled;

        //refund rest amount of deposit to the planner
        IDCAPool(dcaPool).refundTokenForCanceledOrder(msg.sender, order.stableCoin, order.restAmount);
        //refund rest lock cdca to the pilot
        IERC20(cdcaToken).transfer(order.dcaAutopilot, lockAmountOfPilot[order.dcaAutopilot]);
        lockAmountOfPilot[order.dcaAutopilot] = 0;
    }

    ///@notice internal function to run a task of an order and update its states
    function swapAndUpdateOrder(uint256 _orderId) internal override {
        Order memory order = orderList[_orderId];

        IDCAPool(dcaPool).swapToken(
            order.dcaPlanner,
            order.stableCoin,
            dcaTokenList[order.dcaToken].tokenAddress,
            order.nextDCASwapAmount
        );

        orderList[_orderId].restAmount =
            order.depositAmount -
            order.nextDCASwapAmount;
        orderList[_orderId].nextDCASwapAmount = getNextSwapAmount(
            order.nextDCASwapAmount,
            orderList[_orderId].restAmount,
            order.option,
            order.variance
        );
        orderList[_orderId].nextDCASwapTime = order.nextDCASwapTime + order.cycle;
        if (orderList[_orderId].restAmount == 0)
            orderList[_orderId].status = OrderStatus.Completed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interface/IERC20.sol";
import "./interface/IDCAPool.sol";

contract DCAOrderSystemCore is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum OrderStatus {
        Active,
        Completed,
        Canceled
    }

    enum OrderOption {
        Flat,
        Increase,
        Decrease
    }

    ///@notice struct for DCA tokens: WETH, WBNB, ....
    struct DCAToken {
        address tokenAddress;
        string symbol;
    }

    ///@struct for order
    struct Order {
        uint256 orderId;
        address dcaPlanner;
        address dcaAutopilot;
        address stableCoin; //deposted token address
        uint8 dcaToken; //id of dca token
        OrderOption option;
        uint256 cycle; //interval of swap
        uint256 startTime;
        uint256 depositAmount;
        uint256 restAmount; //the rest amount of an other has to be swapped in further tasks
        uint8 variance;
        uint256 nextDCASwapAmount; //the amount of next swap
        uint256 nextDCASwapTime; //time of the next swap
        OrderStatus status;
    }

    struct HistoryOrder {
        uint256 orderId;
        uint256 startTime;
        uint256 endTime;
        bool isComplete; //false: ban true: complete
    }

    address public dcaPool; //DCAPool address
    address public cdcaToken; //CDCA token address

    address public adminWallet;
    EnumerableSet.AddressSet dcaAutoPilots; //auto pilots

    uint16 public rewardRate; //reward/lock rate for an order;parts per thousand

    uint8 public constant penaltyLimit = 3;
    uint16 public pilotTotalNumber;

    mapping(address => bool) public pilotBanList;
    mapping(address => int8) public pilotWeeklyScore; //weekly socre of pilot.
    mapping(address => uint8) public pilotBadCount; // pilot => number of his missing task
    mapping(address => HistoryOrder[]) orderHistoryOfPilot;
    uint256 public deadline; //the time period allows the autopilots can still run their task; after this time he is banned from this order and his fund is locked permanatly

    mapping(address => uint256) public lockAmountOfPilot;
    mapping(address => uint256) public orderBook; //mapping of pilot => current order id

    mapping(uint8 => DCAToken) public dcaTokenList; //list of DCA tokens; token id => its data
    mapping(uint256 => Order) orderList; //list of orders; order id => its data
    mapping(uint256 => EnumerableSet.UintSet) dailyOrderList;

    uint8 public dcaTokenNumber; //number of dca tokens of current service
    uint256 public totalOrderNumber; //total number of orders

    modifier onlyAdmin() {
        require(msg.sender == adminWallet, "You are not a pilot or admin!");
        _;
    }

    modifier onlyPilot() {
        require(dcaAutoPilots.contains(msg.sender), "You are not a pilot!");
        _;
    }

    event NewPilot(address account);

    ///@notice register DCA tokens and their symbols;
    function addDCATokens(
        address[] memory _tokenAddresses,
        string[] memory _symbols
    ) external onlyOwner {
        require(
            _tokenAddresses.length == _symbols.length,
            "Invalid param length!"
        );
        for (uint256 i; i < _tokenAddresses.length; i++) {
            dcaTokenList[dcaTokenNumber++] = DCAToken(
                _tokenAddresses[i],
                _symbols[i]
            );
        }
    }

    ///@notice function to add an order
    function addOrder(
        address _stableCoin,
        uint8 _dcaToken,
        OrderOption _option,
        uint256 _cycle,
        uint256 _depositAmount,
        uint256 _nextSwapAmount,
        uint8 _variance
    ) public virtual {
        IERC20(_stableCoin).transferFrom(msg.sender, dcaPool, _depositAmount);
        uint256 orderId = totalOrderNumber + 1;
        uint256 runTime = block.timestamp + _cycle;
        orderList[orderId] = Order(
            orderId,
            msg.sender,
            address(0),
            _stableCoin,
            _dcaToken,
            _option,
            _cycle,
            block.timestamp,
            _depositAmount,
            _depositAmount,
            _variance,
            _nextSwapAmount,
            block.timestamp + _cycle,
            OrderStatus.Active
        );
        dailyOrderList[runTime / 1 days].add(orderId);
        totalOrderNumber++;
    }

    ///@notice internal function to get the next swap amount of an order
    function getNextSwapAmount(
        uint256 _currentSwapAmount,
        uint256 _restAmount,
        OrderOption _option,
        uint8 _variance
    ) internal pure returns (uint256) {
        if (_option == OrderOption.Flat) return _currentSwapAmount;
        else if (_option == OrderOption.Increase) {
            uint256 calcAmount = (_currentSwapAmount * (100 + _variance)) / 100;
            if (calcAmount > _restAmount) return calcAmount;
            else return _restAmount;
        } else {
            uint256 calcAmount = (_currentSwapAmount * (100 - _variance)) / 100;
            if (calcAmount > _restAmount) return calcAmount;
            else return _restAmount;
        }
    }

    ///@notice read daily total orders
    function getDailyOrders(uint256 _day)
        external
        view
        returns (Order[] memory)
    {
        uint256 dailyOrderNumber = dailyOrderList[_day].length();
        Order[] memory dailyOrders = new Order[](dailyOrderNumber);
        for (uint256 i; i < dailyOrderNumber; i++) {
            dailyOrders[i] = orderList[dailyOrderList[_day].at(i)];
        }
        return dailyOrders;
    }

    function getDailyAdminOrders(uint256 _day)
        external
        view
        returns (Order[] memory)
    {
        uint256 dailyOrderNumber = dailyOrderList[_day].length();
        uint256 numberOfAdminOrders;
        uint256[] memory adminOrderNumbers = new uint256[](dailyOrderNumber);
        for (uint256 i; i < dailyOrderNumber; i++) {
            if (
                orderList[dailyOrderList[_day].at(i)].dcaAutopilot ==
                adminWallet
            ) {
                adminOrderNumbers[numberOfAdminOrders] = orderList[
                    dailyOrderList[_day].at(i)
                ].orderId;
                numberOfAdminOrders++;
            }
        }

        Order[] memory dailyAdminOrders = new Order[](numberOfAdminOrders);
        for (uint256 i; i < numberOfAdminOrders; i++) {
            dailyAdminOrders[i] = orderList[adminOrderNumbers[i]];
        }
        return dailyAdminOrders;
    }

    ///@notice get daily public orders that the autoPilots not run yet.
    function getDailyMissedOrders(uint256 _day)
        external
        view
        returns (Order[] memory)
    {
        uint256 dailyOrderNumber = dailyOrderList[_day].length();
        uint256 numberOfMissedOrders;
        uint256[] memory missedOrderNumbers = new uint256[](dailyOrderNumber);
        for (uint256 i; i < dailyOrderNumber; i++) {
            if (
                block.timestamp >
                orderList[dailyOrderList[_day].at(i)].nextDCASwapTime + deadline
            ) {
                missedOrderNumbers[numberOfMissedOrders] = orderList[
                    dailyOrderList[_day].at(i)
                ].orderId;
                numberOfMissedOrders++;
            }
        }

        Order[] memory dailyMissedOrders = new Order[](numberOfMissedOrders);
        for (uint256 i; i < numberOfMissedOrders; i++) {
            dailyMissedOrders[i] = orderList[missedOrderNumbers[i]];
        }
        return dailyMissedOrders;
    }

    ///@notice the order autoPilot can call this function to run his task
    function runPilotTask() external onlyPilot {
        Order memory order = orderList[orderBook[msg.sender]];
        require(
            block.timestamp >= order.nextDCASwapTime &&
                block.timestamp <= order.nextDCASwapTime + deadline,
            "Can't run this task!"
        );
        require(
            order.status == OrderStatus.Active,
            "This tast already completed or canceled."
        );
        uint256 rewardAmount = (order.nextDCASwapAmount * rewardRate) / 1000;

        swapAndUpdateOrder(order.orderId);

        IDCAPool(dcaPool).rewardPilotAndPlanner(
            msg.sender,
            order.dcaPlanner,
            rewardAmount
        );
        //unlock pilot credit for this task
        lockAmountOfPilot[msg.sender] -= rewardAmount;
        IERC20(cdcaToken).transfer(msg.sender, rewardAmount);

        pilotWeeklyScore[msg.sender] += 1;

        checkOrderComplete(order.orderId);
    }

    ///@notice all pilots and admin can call public order
    function runAdminTask(uint256 _orderId) external onlyAdmin {
        Order memory order = orderList[_orderId];
        require(
            block.timestamp > order.nextDCASwapTime + deadline,
            "Can't run this task!"
        );
        require(
            order.status == OrderStatus.Active,
            "This tast already completed or canceled."
        );

        address pilot = order.dcaAutopilot;

        //lock credit of the pilot of this task
        if (pilot != adminWallet && pilot != address(0)) {
            IERC20(cdcaToken).transfer(dcaPool, lockAmountOfPilot[pilot]);
            lockAmountOfPilot[pilot] = 0;
            pilotBadCount[pilot] += 1;
            pilotWeeklyScore[pilot] -= 1;
            if (pilotBadCount[pilot] == 3) {
                pilotBanList[pilot] = true;
                dcaAutoPilots.remove(pilot);
                delete pilotWeeklyScore[pilot];
                delete orderBook[pilot];
            }
        }
        if (pilot == address(0)) {
            orderList[_orderId].dcaAutopilot = adminWallet;
        }

        uint256 rewardAmount = (order.nextDCASwapAmount * rewardRate) / 1000;

        swapAndUpdateOrder(_orderId);

        IDCAPool(dcaPool).rewardPilotAndPlanner(
            msg.sender,
            order.dcaPlanner,
            rewardAmount
        );

        checkOrderComplete(_orderId);
    }

    function checkOrderComplete(uint256 _orderId) internal virtual {
        if (orderList[_orderId].restAmount == 0) {
            orderList[_orderId].status = OrderStatus.Completed;
            if (orderList[_orderId].dcaAutopilot != address(0)) {
                delete orderBook[orderList[_orderId].dcaAutopilot];
            }
        }
    }

    function readDCAPilots() external view returns(address[] memory) {
        uint256 pilotsNumber = dcaAutoPilots.length();
        address[] memory pilots = new address[](pilotsNumber);
        for (uint i; i < pilotsNumber; i ++) {
            pilots[i] = dcaAutoPilots.at(i);
        }  
        return pilots;
    }

    function readWeeklyGoodDCAPilots() external view returns(address[] memory, uint256) {
        uint256 pilotsNumber = dcaAutoPilots.length();
        uint256 numberOfGoodPilots;
        address[] memory goodPilots = new address[](pilotsNumber);
        for (uint i; i < pilotsNumber; i ++) {
            address pilot = dcaAutoPilots.at(i);
            if (pilotWeeklyScore[pilot] > 0) {
                goodPilots[numberOfGoodPilots] = pilot;
                numberOfGoodPilots ++;
            }
        }  
        return (goodPilots, numberOfGoodPilots);
    }

    function resetWeeklyScore() external {
        uint256 pilotNumber = dcaAutoPilots.length();
        for (uint i; i < pilotNumber; i++) {
            pilotWeeklyScore[dcaAutoPilots.at(i)] = 0;
        }
    }

    ///@notice internal function to run a task of an order and update its states
    function swapAndUpdateOrder(uint256 _orderId) internal virtual {}

    function setCDCAToken(address _cdcaToken) external onlyOwner {
        cdcaToken = _cdcaToken;
    }

    function setDCAPool(address _dcaPool) external onlyOwner {
        dcaPool = _dcaPool;
    }

    function setAdminWallet(address _adminWallet) external onlyOwner {
        adminWallet = _adminWallet;
    }

    function setDeadline(uint256 _deadline) external onlyOwner {
        deadline = _deadline;
    }

    function setPilotNumber(uint16 _pilotTotalNumber) external onlyOwner {
        pilotTotalNumber = _pilotTotalNumber;
    }

    /////////functions for piltos///////////
    function register() public {
        require(
            !dcaAutoPilots.contains(msg.sender),
            "You are already registered!"
        );
        require(
            dcaAutoPilots.length() < pilotTotalNumber,
            "No more pilots acceptable in the system."
        );
        dcaAutoPilots.add(msg.sender);
        emit NewPilot(msg.sender);
    }

    function pickOrder(uint256 _orderId) public onlyPilot {
        require(orderBook[msg.sender] == 0, "You already have an order.");
        require(
            orderList[_orderId].dcaAutopilot == address(0),
            "That was already picked!"
        );
        uint256 lockAmount = (orderList[_orderId].restAmount * rewardRate) /
            1000;
        IERC20(cdcaToken).transferFrom(msg.sender, address(this), lockAmount);
        lockAmountOfPilot[msg.sender] = lockAmount;
        orderBook[msg.sender] = _orderId;
    }
    /////////////
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IDCAPool {
    function swapAndDepositToken(
        address,
        address,
        address,
        uint256,
        uint256
    ) external;

    function swapToken(
        address,
        address,
        address,
        uint256
    ) external;

    function rewardPilotAndPlanner(
        address,
        address,
        uint256
    ) external;

    function refundTokenForCanceledOrder(
        address,
        address,
        uint256
    ) external;

    function lockFund(
        address,
        address,
        uint256,
        uint256
    ) external;

    function withdrawAll(
        uint256,
        address,
        address,
        address
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns(uint8);
}