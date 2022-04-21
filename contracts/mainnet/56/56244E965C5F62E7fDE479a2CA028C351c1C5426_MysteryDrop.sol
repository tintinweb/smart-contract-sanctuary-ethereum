// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ICollectionV3.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/AggregatorInterface.sol";

contract MysteryDrop is ReentrancyGuard {
    // Add the library methods
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

/*==================================================== Events ==========================================================*/

    event CollectionsTiersSet(Tiers tier, address collection, uint256[] ids);
    event MysteryBoxDropped(
        Tiers tier,
        address collection,
        uint256 id,
        address user
    );
    event MysteryBoxCC(Tiers tier, address user, string purchaseId);

/*==================================================== Modifiers ==========================================================*/

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not Authorized");
        _;
    }

    modifier isStarted() {
        require(startTime <= block.timestamp && endTime > block.timestamp, "Drop has not started yet!");
        _;
    }

   

/*==================================================== State Variables ==========================================================*/

    enum Tiers {
        TierOne,
        TierTwo,
        TierThree
    }

    // These will keep decks' indexes
    EnumerableSet.UintSet private firstDeckIndexes;
    EnumerableSet.UintSet private secondDeckIndexes;
    EnumerableSet.UintSet private thirdDeckIndexes;

    //index counter
    Counters.Counter public firstDeckIndexCounter;
    Counters.Counter public secondDeckIndexCounter;
    Counters.Counter public thirdDeckIndexCounter;

    bytes[] public firstDeck;
    bytes[] public secondDeck;
    bytes[] public thirdDeck;

    // address of the admin
    address admin;
    //start/end time of the contract
    uint256 public startTime;
    uint256 public endTime;
    // Tier price infos
    mapping(Tiers => uint256) public tierPrices;
    // Collection card number infos
    mapping(address => uint256) private cardNumbers;
    mapping(address => bool) private authorizedAddresses;
    IERC20 ern;
    // ERN price feed contract
    AggregatorInterface ernOracleAddr;

    //Deck Max Size
    uint32 public firstDeckLimit = 0;
    uint32 public secondDeckLimit = 0;
    uint32 public thirdDeckLimit = 0;

/*==================================================== Constructor ==========================================================*/

    constructor(IERC20 _ern, AggregatorInterface _ernOracle) {
        ern = _ern;
        ernOracleAddr = _ernOracle;
        admin = msg.sender;
        startTime = 0;
        endTime = 0;
    }

/*==================================================== Functions ==========================================================*/

/*==================================================== Read Functions ==========================================================*/

    /*
     *Returns the current price of the ERN token
    */
    function getPrice() public view returns (uint256) {
        return uint256(ernOracleAddr.latestAnswer());
    }

    /*
     *Returns the amount of the ERN token to transfer
    */
    function computeErnAmount(uint256 _subscriptionPrice, uint256 _ernPrice)
        public
        pure
        returns (uint256)
    {
        uint256 result = (_subscriptionPrice * 10**18) / _ernPrice;
        return result;
    }

    /*
     *Internal Returns the random card
    */
    function _getRandom(uint256 gamerange, uint256 seed)
        internal
        view
        virtual
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            uint256(
                                keccak256(abi.encodePacked(block.coinbase))
                            ) +
                            seed
                    )
                )
            ) % gamerange;
    }

    /*
     * Get the number of available boxes for a tier
     */
    function getAvailable(Tiers _tier) public view returns (uint256) {
        if (_tier == Tiers.TierOne) {
            return firstDeckIndexes.length();
        } else if (_tier == Tiers.TierTwo) {
            return secondDeckIndexes.length();
        } else if (_tier == Tiers.TierThree) {
            return thirdDeckIndexes.length();
        }
        return 0;
    }


/*==================================================== External Functions ==========================================================*/

    /*
     *This function sets the collection with the cards by admin via internal call
    */
    function setCollection(
        Tiers _tier,
        address _collection,
        uint256[] calldata _ids
    ) external onlyAdmin {
        uint256 length = _ids.length;
        for (uint16 i = 0; i < length; ) {
            _setCollection(_tier, _collection, _ids[i]);
            unchecked {
                ++i;
            }
        }
        emit CollectionsTiersSet(_tier, _collection, _ids);
    }

    /*
     *This function sets the collections with the cards by admin via internal call
    */
    function setCollectionsBatch(
        Tiers _tier,
        address[] calldata _collections,
        uint256[] calldata _ids
    ) external onlyAdmin {
        uint256 last;
        for (uint256 j = 0; j < _collections.length; j++) {
            for (
                uint256 i = last;
                i < last + cardNumbers[_collections[j]];
                i++
            ) {
                _setCollection(_tier, _collections[j], _ids[i]);
            }
            last += cardNumbers[_collections[j]];
        }
    }

    /*
     *This function resets the decks by the admin
    */
    function resetTierDeck(Tiers _tier) external onlyAdmin {
        if (_tier == Tiers.TierOne) {
            firstDeck = new bytes[](0);
            firstDeckIndexCounter._value = 0;
            for (
                uint256 i = 0;
                i < firstDeckIndexes._inner._values.length;
                i++
            ) {
                firstDeckIndexes._inner._indexes[
                    firstDeckIndexes._inner._values[i]
                ] = 0;
            }
            firstDeckIndexes._inner._values = new bytes32[](0);
        } else if (_tier == Tiers.TierTwo) {
            secondDeck = new bytes[](0);
            secondDeckIndexCounter._value = 0;
            for (
                uint256 i = 0;
                i < secondDeckIndexes._inner._values.length;
                i++
            ) {
                secondDeckIndexes._inner._indexes[
                    secondDeckIndexes._inner._values[i]
                ] = 0;
            }
            secondDeckIndexes._inner._values = new bytes32[](0);
        } else if (_tier == Tiers.TierThree) {
            thirdDeck = new bytes[](0);
            thirdDeckIndexCounter._value = 0;
            for (
                uint256 i = 0;
                i < thirdDeckIndexes._inner._values.length;
                i++
            ) {
                thirdDeckIndexes._inner._indexes[
                    thirdDeckIndexes._inner._values[i]
                ] = 0;
            }
            thirdDeckIndexes._inner._values = new bytes32[](0);
        } else revert("wrong parameter!");
    }

    /*
     *This function sets the card prices per Tier by the admin
    */
    function tierPricesSet(Tiers[] memory _tiers, uint256[] memory _prices)
        external
        onlyAdmin
    {
        for (uint8 i = 0; i < _tiers.length; i++) {
            tierPrices[_tiers[i]] = _prices[i];
        }
    }

    /*
     *This function sets the number of cards per collection by admin
    */
    function setCardNumbers(
        address[] calldata _collections,
        uint256[] calldata numberofIds
    ) external onlyAdmin {
        for (uint256 i = 0; i < _collections.length; i++) {
            cardNumbers[_collections[i]] = numberofIds[i];
        }
    }
    /*
     *This function sets the authorized address for Credit Card sell
    */
    function setAuthorizedAddr(address _addr) external onlyAdmin{
        authorizedAddresses[_addr] = true;
    }

    /*
     *This function removes the authorized address for Credit Card sell
    */
    function removeAuthorizedAddr(address _addr) external onlyAdmin{
        authorizedAddresses[_addr] = false;
    }
    

    /*
     *User can buy mysteryBox via this function with creditcard
    */
   function buyCreditMysteryBox(address _user, Tiers _tier, string calldata _purchaseId) external onlyAuthorized {
        _buy(_user, _tier);
        emit MysteryBoxCC(_tier, _user, _purchaseId);
    }


    /*
     *User can buy mysteryBox via this function with token payment
    */
    function buyMysteryBox(Tiers _tier) external isStarted nonReentrant {
        uint256 _ernAmount = _buy(msg.sender, _tier);
        ern.transferFrom(msg.sender, address(this), _ernAmount);
    }

    /*
     *Admin can start the contract via this function
    */
    function setTimestamps(uint256 _start, uint256 _end) external onlyAdmin {
        startTime = _start;
        endTime = _end;
    }

    /*
     *Admin can withdraw earning with given amount
    */
    function withdrawFundsPartially(uint256 _amount, address _to)
        external
        onlyAdmin
    {
        require(
            ern.balanceOf(address(this)) >= _amount,
            "Amount exceeded ern balance"
        );
        ern.transfer(_to, _amount);
    }

    /*
     *Admin can withdraw all of th earning
    */
    function withdrawAllFunds(address _to) external onlyAdmin {
        uint256 _balance = ern.balanceOf(address(this));
        ern.transfer(_to, _balance);
    }

    /*
    * This functions set the decks maximum limit
    */ 
    function setDeckMaxLimit(uint32 first, uint32 second, uint32 third) external onlyAdmin {
        firstDeckLimit = first;
        secondDeckLimit = second;
        thirdDeckLimit = third;
    }

    /*
    * This functions set the admin of the contract
    */ 
    function setAdmin(address _admin) external onlyAdmin {
       require(_admin != address(0), "Not allowed to renounce admin");
       admin = _admin;
    }


/*==================================================== Internal Functions ==========================================================*/

    /*
     *This function picks random card and mints this random card to user
    */
    function _buy(address _user, Tiers _tier) internal returns (uint256) {
        uint256 _ernPrice = getPrice();
        uint256 ernAmount;
        uint256 random;
        uint256 index;
        address _contract;
        uint256 _id;
        if (_tier == Tiers.TierOne) {
            require(
                firstDeckIndexes.length() > 0,
                "There is no card left in Tier 1!"
            );
            ernAmount = computeErnAmount(tierPrices[Tiers.TierOne], _ernPrice);
            random = _getRandom(firstDeckIndexes.length(), _ernPrice);
            index = firstDeckIndexes.at(random);
            firstDeckIndexes.remove(index);
            (_contract, _id) = abi.decode(firstDeck[index], (address, uint256));
        } else if (_tier == Tiers.TierTwo) {
            require(
                secondDeckIndexes.length() > 0,
                "There is no card left in Tier 2!"
            );
            ernAmount = computeErnAmount(tierPrices[Tiers.TierTwo], _ernPrice);
            random = _getRandom(secondDeckIndexes.length(), _ernPrice);
            index = secondDeckIndexes.at(random);
            secondDeckIndexes.remove(index);
            (_contract, _id) = abi.decode(
                secondDeck[index],
                (address, uint256)
            );
        } else if (_tier == Tiers.TierThree) {
            require(
                thirdDeckIndexes.length() > 0,
                "There is no card left in Tier 3!"
            );
            ernAmount = computeErnAmount(
                tierPrices[Tiers.TierThree],
                _ernPrice
            );
            random = _getRandom(thirdDeckIndexes.length(), _ernPrice);
            index = thirdDeckIndexes.at(random);
            thirdDeckIndexes.remove(index);
            (_contract, _id) = abi.decode(thirdDeck[index], (address, uint256));
        } else {
            revert("Wrong Tier Parameter!");
        }

        ICollectionV3(_contract).mint(_user, _id);
        emit MysteryBoxDropped(_tier, _contract, _id, _user);
        return ernAmount;
    }

    /*
     *This function sets the collection with the cards by admin
    */
    function _setCollection(
        Tiers _tier,
        address _collection,
        uint256 _id
    ) internal {
        if (_tier == Tiers.TierOne) {
            require(firstDeck.length <= firstDeckLimit, "More than Tier Limit!");
            firstDeck.push(abi.encode(_collection, _id));
            firstDeckIndexes.add(firstDeckIndexCounter.current());
            firstDeckIndexCounter.increment();
        } else if (_tier == Tiers.TierTwo) {
            require(secondDeck.length <= secondDeckLimit, "More than Tier Limit!");
            secondDeck.push(abi.encode(_collection, _id));
            secondDeckIndexes.add(secondDeckIndexCounter.current());
            secondDeckIndexCounter.increment();
        } else if (_tier == Tiers.TierThree) {
            require(thirdDeck.length <= thirdDeckLimit, "More than Tier Limit!");
            thirdDeck.push(abi.encode(_collection, _id));
            thirdDeckIndexes.add(thirdDeckIndexCounter.current());
            thirdDeckIndexCounter.increment();
        } else {
            revert("Wrong Tier Parameter!");
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity 0.8.12;


interface ICollectionV3 { 

    function initialize(   
        string memory uri,
        uint256 _total,
        uint256 _whitelistedStartTime,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _amount,
        uint256 _percent,
        address _admin,
        address _facAddress
    )external;

    function __CollectionV3_init_unchained(
        string memory uri,
        uint256 _total,
        uint256 _whitelistedStartTime,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _amount,
        uint256 _percent,
        address _admin,
        address _facAddress
    ) external;

    function addExternalAddresses(address _token,address _stone,address _treasure) external ;

    function recoverToken(address _token) external;
  
    function changeOnlyWhitelisted(bool _status) external ;

    function buy(address buyer, uint256 _id) external;

    function mint(address to, uint256 _id) external;

    function mintBatch( address to, uint256[] memory ids, uint256[] memory amount_) external ;

    function addPayees(address[] memory payees_, uint256[] memory sharePerc_) external;

    function _addPayee(address account, uint256 sharePerc_) external;

    function release() external;

    function getAmountPer(uint256 sharePerc) external view returns (uint256);

    function calcPerc(uint256 _amount, uint256 _percent) external pure returns (uint256);

    function calcTrasAndShare() external view returns (uint256, uint256);

    function setStarTime(uint256 _starTime) external;  

    function setEndTime(uint256 _endTime)external;

    function setWhiteListUser(address _addr) external;

    function setBatchWhiteListUser(address[] calldata _addr) external;

    function setAmount(uint256 _amount) external;

    function delShare(address account) external;

    function totalReleased() external view returns (uint256);

    function released(address account) external view returns (uint256);

    function shares(address account) external view returns (uint256);

    function allShares() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256 answer);
}