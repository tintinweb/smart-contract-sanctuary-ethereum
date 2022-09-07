// SPDX-License-Identifier: UNLICENSED
// @Credits Unicrypt Network 2021

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IERC20.sol";
import "./IPresaleSettings.sol";

/// @title Settings to initialize presale contracts and edit fees.
/// @notice These settings includes fees, limits, penalties and addresses
contract PresaleSettings is Ownable, IPresaleSettings {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private feeWhitelist;
    uint constant MAX_PERCENTAGE_ALLOWED = 1000;

    struct Settings {
        uint256 BASE_FEE; // base fee divided by 1000
        uint256 TOKEN_FEE; // token fee divided by 1000
        address payable ETH_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
        uint256 ETH_CREATION_FEE; // fee to generate a presale contract on the platform
        uint256 MAX_PRESALE_LENGTH; // maximum difference between start and endblock
        uint256 WITHDRAW_PENALTY_PERCENT;
        uint256 EMERGENCY_WITHDRAW_PREVENTION_TIME;
        uint256 CANCELLATION_PERIOD;
        DateSettings DATES;
        LiquiditySettings LIQUIDITY_LIMITS;
        uint256 REBALANCING;
    }

    struct LiquiditySettings {
        uint256 MIN_LIQUIDITY;
        uint256 MAX_LIQUIDITY;
    }

    struct DateSettings {
        uint256 MIN_START_DATE;
        uint256 MIN_END_DATE;
        uint256 MIN_LOCK_PERIOD;
    }
    
    Settings public SETTINGS;
    
    constructor()  {
        SETTINGS.BASE_FEE = 18; // 1.8%
        SETTINGS.TOKEN_FEE = 18; // 1.8%
        SETTINGS.ETH_CREATION_FEE = 5e17;
        SETTINGS.ETH_FEE_ADDRESS = payable(msg.sender);
        SETTINGS.TOKEN_FEE_ADDRESS = payable(msg.sender);
        SETTINGS.MAX_PRESALE_LENGTH = 8 weeks;  // 0 means that there is not limit
        SETTINGS.WITHDRAW_PENALTY_PERCENT = 200;
        SETTINGS.DATES.MIN_START_DATE = 10 minutes;
        SETTINGS.DATES.MIN_END_DATE = 10 minutes;
        SETTINGS.DATES.MIN_LOCK_PERIOD = 4 weeks;
        SETTINGS.EMERGENCY_WITHDRAW_PREVENTION_TIME = 10 minutes;
        SETTINGS.LIQUIDITY_LIMITS.MIN_LIQUIDITY = 510;
        SETTINGS.LIQUIDITY_LIMITS.MAX_LIQUIDITY = 1000;
        SETTINGS.CANCELLATION_PERIOD = 2 days;
        SETTINGS.REBALANCING = 0;
    }


    function getMinLiquidity () external view returns (uint256) {
        return SETTINGS.LIQUIDITY_LIMITS.MIN_LIQUIDITY;
    }

    function getMaxLiquidity() external view returns (uint256) {
        return SETTINGS.LIQUIDITY_LIMITS.MAX_LIQUIDITY;
    }

    function getMaxPresaleLength () external view returns (uint256) {
        return SETTINGS.MAX_PRESALE_LENGTH;
    }

    function getCancelPeriod() external view returns (uint256) {
        return SETTINGS.CANCELLATION_PERIOD;
    }

    function getWithdrawPenaltyPercent () external view returns (uint256) {
        return SETTINGS.WITHDRAW_PENALTY_PERCENT;
    }
    function getEmergencyWithdrawPreventionTime() external view returns (uint256) {
        return SETTINGS.EMERGENCY_WITHDRAW_PREVENTION_TIME;
    }

    function getMinStartDate() external view returns (uint256) {
        return SETTINGS.DATES.MIN_START_DATE;
    }

    function getMinEndDate() external view returns (uint256) {
        return SETTINGS.DATES.MIN_END_DATE;
    }

    function getMinLockPeriod() external view returns (uint256) {
        return SETTINGS.DATES.MIN_LOCK_PERIOD;
    }
    
    function getBaseFee () external view returns (uint256) {
        return SETTINGS.BASE_FEE;
    }

    function getRebalancingPercentage() external view returns (uint256) {
        return SETTINGS.REBALANCING;
    }
    
    function getTokenFee () external view returns (uint256) {
        return SETTINGS.TOKEN_FEE;
    }
    
    function getEthCreationFee () external view returns (uint256) {
        return SETTINGS.ETH_CREATION_FEE;
    }
    
    function getEthAddress () external view returns (address payable) {
        return SETTINGS.ETH_FEE_ADDRESS;
    }
    
    function getTokenFeeAddress () external view returns (address payable) {
        return SETTINGS.TOKEN_FEE_ADDRESS;
    }
    
    function setFeeAddresses(address payable _ethAddress, address payable _tokenFeeAddress) external onlyOwner {
        SETTINGS.ETH_FEE_ADDRESS = _ethAddress;
        SETTINGS.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }
    
    function setFees(uint256 _baseFee, uint256 _tokenFee, uint256 _ethCreationFee) external onlyOwner {

        require(_baseFee < 200, 'MAX BASE FEE'); //20% max fee
        require(_tokenFee < 200, 'MAX TOKEN FEE');  //20% max fee
        require(_ethCreationFee < 5e18, 'MAX ETH FEE');  //5BNB max fee

        SETTINGS.BASE_FEE = _baseFee;
        SETTINGS.TOKEN_FEE = _tokenFee;
        SETTINGS.ETH_CREATION_FEE = _ethCreationFee;
    }
    
    function setMaxPresaleLength(uint256 _maxLength) external onlyOwner {
        SETTINGS.MAX_PRESALE_LENGTH = _maxLength;
    }

    function setCancelPeriod(uint256 _cancelPeriod) external onlyOwner {
        SETTINGS.CANCELLATION_PERIOD = _cancelPeriod;
    }

    function setMaxLiquidity(uint256 _maxLiq) external onlyOwner {
        require(_maxLiq <= MAX_PERCENTAGE_ALLOWED, 'PresaleSettings: invalid percentage, it must be lower than 1000');
        require(_maxLiq >= SETTINGS.LIQUIDITY_LIMITS.MIN_LIQUIDITY, 'PresaleSettings: invalid percentage, Max liquidity must be greater than Min liquidity');
        SETTINGS.LIQUIDITY_LIMITS.MAX_LIQUIDITY = _maxLiq;
    }

    function setMinLiquidity(uint256 _minLiq) external onlyOwner {
        require(_minLiq <= MAX_PERCENTAGE_ALLOWED, 'PresaleSettings: invalid percentage, it must be lower than 1000');
        require(SETTINGS.LIQUIDITY_LIMITS.MAX_LIQUIDITY >= _minLiq, 'PresaleSettings: invalid percentage, Max liquidity must be greater than Min liquidity');
        SETTINGS.LIQUIDITY_LIMITS.MIN_LIQUIDITY = _minLiq;
    }

    function setWithdrawPenaltyPercent(uint256 _penaltyPercent) external onlyOwner {
        require(_penaltyPercent <= MAX_PERCENTAGE_ALLOWED, 'PresaleSettings: invalid percentage, it must be lower than 1000');
        SETTINGS.WITHDRAW_PENALTY_PERCENT = _penaltyPercent;
    }

    function setEmergencyWithdrawPreventionTime(uint256 _emergencyWithdrawPreventionTime) external onlyOwner {
        SETTINGS.EMERGENCY_WITHDRAW_PREVENTION_TIME = _emergencyWithdrawPreventionTime;
    }

    function setRebalancingPercentage(uint256 _rebalancing) external onlyOwner {
        require(_rebalancing <= MAX_PERCENTAGE_ALLOWED, 'PresaleSettings: invalid rebalancing percentage, it must be lower than 1000');
        SETTINGS.REBALANCING = _rebalancing;
    }

    function setMinStartDate(uint256 _minStartDate) external onlyOwner {
        SETTINGS.DATES.MIN_START_DATE = _minStartDate;
    }

    function setMinEndDate(uint256 _minEndDate) external onlyOwner {
        SETTINGS.DATES.MIN_END_DATE = _minEndDate;
    }

    function setMinLockPeriod(uint256 _minLockPeriod) external onlyOwner {
        SETTINGS.DATES.MIN_LOCK_PERIOD = _minLockPeriod;
    }

    // whitelist
    function getFeeWhitelistTokenLength () external view returns (uint256) {
        return feeWhitelist.length();
    }

    function getFeeWhitelistTokenAtIndex (uint256 _index) external view returns (address) {
        return feeWhitelist.at(_index);
    }

    function getFeeWhitelistTokenStatus (address _token) external view returns (bool) {
        return feeWhitelist.contains(_token);
    }

    function addFeeWhitelistToken(address _token) public onlyOwner {
            feeWhitelist.add(_token);
    }

    function removeFeeWhitelistToken(address _token) public onlyOwner {
        feeWhitelist.remove(_token);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

/// @title Interface that needs to be implemented by ERC20 tokens
interface IERC20Token {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

/// @title Interface needed for the settings needed in a presale
interface IPresaleSettings {
    function getMaxPresaleLength () external view returns (uint256);
    function getBaseFee () external view returns (uint256);
    function getTokenFee () external view returns (uint256);
    function getEthAddress () external view returns (address payable);
    function getTokenFeeAddress () external view returns (address payable);
    function getEthCreationFee () external view returns (uint256);
    function getWithdrawPenaltyPercent () external view returns (uint256);
    function getEmergencyWithdrawPreventionTime () external view returns (uint256);
    function getMinStartDate () external view returns (uint256);
    function getMinEndDate () external view returns (uint256);
    function getMinLiquidity () external view returns (uint256);
    function getMaxLiquidity () external view returns (uint256);
    function getFeeWhitelistTokenStatus (address _token) external view returns (bool);
    function getCancelPeriod() external view returns (uint256);
    function getMinLockPeriod() external view returns (uint256);
    function getRebalancingPercentage() external view returns (uint256);
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