/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// Sources flattened with hardhat v2.9.5 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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


// File @openzeppelin/contracts/utils/structs/[email protected]


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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}


// File contracts/AnyCallBase.sol

pragma solidity ^0.8.0;



interface CallProxy{
  function anyCall(
      address _to,
      bytes calldata _data,
      address _fallback,
      uint256 _toChainID,
      uint256 _flags
  ) external;
}

contract AnyCallBase is Initializable {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using Counters for Counters.Counter;
    
  Counters.Counter internal _requestId;
  EnumerableSet.UintSet internal _sentRequestIds; 
  EnumerableSet.UintSet internal _supportedChainIds;
  EnumerableSet.AddressSet internal _callers;
  mapping(address=>mapping(uint=>bool)) internal _callerChainIdAllowed;

  address internal _owner;
  address internal _anyCallProxy;
  uint internal _flags;
  address internal _fallback;
  
  event ProcessRequest(bytes message);

  modifier onlyOwner {
    require(msg.sender == _owner, 'Not owner');
    _;
  }

  function initialize(
    address anyCallProxy
  ) initializer public {
    _owner = msg.sender;
    _anyCallProxy = anyCallProxy;
    _flags = 0; 
    _fallback = address(0);
  }

  function getSupportedChainIds() public view returns(uint[] memory) {
    uint n = _supportedChainIds.length();
    uint[] memory chainIds = new uint[](n);
    for (uint i=0; i<n; i++) {
      chainIds[i] = _supportedChainIds.at(i);
    }
    return chainIds;
  }

  function setSupportedChainIds(uint[] memory chainIds) onlyOwner public {
    for (uint i=0; i<chainIds.length; i++) {
      _supportedChainIds.add(chainIds[i]);
    }
  }

  function getCallers() public view returns(address[] memory) {
    uint n = _callers.length();
    address[] memory callers = new address[](n);
    for (uint i=0; i<n; i++) {
      callers[i] = _callers.at(i);
    }
    return callers;
  }

  function isAllowedCaller(address caller, uint chainId) public view returns(bool) {
    require(_supportedChainIds.contains(chainId), 'unsupported chain'); 
    return _callerChainIdAllowed[caller][chainId];
  }

  function allowCaller(address caller, uint chainId, bool allow) onlyOwner public {
    require(_supportedChainIds.contains(chainId), 'unsupported chain'); 
    _callers.add(caller);
    _callerChainIdAllowed[caller][chainId] = allow;
  }

  function setOwner(address owner) public onlyOwner {
    _owner = owner;
  }
  function getOwner() public view returns(address) {
    return _owner;
  }

  function setAnyCallProxy(address anyCallProxy) public onlyOwner {
    _anyCallProxy = anyCallProxy;
  }
  function getAnyCallProxy() public view returns(address) {
    return _anyCallProxy;
  }

  function setFlags(uint flags) onlyOwner public {
    _flags = flags;
  }
  function getFlags() public view returns(uint) {
    return _flags;
  } 



  /// @dev To be overriden by derived contract.
  function _processRequest(
    address caller,
    uint chainId,
    uint requestId, 
    uint requestCode,
    bytes memory requestPayload
  ) internal virtual returns(bytes memory) 
  {
    bytes memory responsePayload = new bytes(2);
    responsePayload[0] = bytes1(uint8(0x1));
    responsePayload[1] = bytes1(uint8(0x2));
    return responsePayload;
  }

  /// @dev  To be overriden by derived contract.
  function _processResponse(
    address caller,
    uint chainId,
    uint requestId,
    uint requestCode,
    bytes memory responsePayload
  ) internal virtual 
  {
    
  }

  function anyExecute(bytes memory data) 
    external returns (bool success, bytes memory result) 
  {
    (
      address caller, 
      uint chainId,
      uint requestId, 
      uint requestCode,
      bytes memory payload // either request payload or payload of response to the request
    ) = abi.decode(data, (address, uint, uint, uint, bytes));

    // require(_callerChainIdAllowed[caller][chainId] == true, "caller is not whitelisted");
    if (_sentRequestIds.contains(requestId)) {
      _processResponse(
        caller,
        chainId,
        requestId,
        requestCode,
        payload // response payload
      );
      _sentRequestIds.remove(requestId);
    } 
    else {
      bytes memory responsePayload = new bytes(1);
      responsePayload[0] = bytes1(uint8(0x1));
      // _processRequest(
      //   caller,
      //   chainId,
      //   requestId, 
      //   requestCode, 
      //   payload // request payload
      // );

      bytes memory message = abi.encode(address(this), requestId, requestCode, responsePayload); 
      emit ProcessRequest(message);
      // CallProxy(_anyCallProxy).anyCall(
      //   caller, // callee = caller
      //   message,
      //   _fallback,
      //   chainId,
      //   _flags
      // );
    }
    success = true;
    result = "";
  }

  function sendRequest(
    address callee, 
    uint chainId,
    uint requestCode, 
    bytes calldata payload
  ) onlyOwner public 
  {
    _requestId.increment();
    uint requestId = _requestId.current();
    bytes memory message = abi.encode(
      address(this), // caller address
      block.chainid, // caller chain id
      requestId, 
      requestCode, 
      payload
    ); 
    CallProxy(_anyCallProxy).anyCall(
      callee,
      message,
      _fallback,
      chainId,
      _flags
    );
    _sentRequestIds.add(requestId);
  }
}


// File contracts/AnyCallCapital.sol

pragma solidity ^0.8.0;


/**
The contract is deployed on the main (polygon) network.
 */
contract AnyCallCapital is Initializable, AnyCallBase {
  event ResponseArrived( 
    address caller,
    uint chainId,
    uint requestId,
    uint requestCode,
    bytes resposnsePayload
  );

  function _processResponse(
    address caller,
    uint chainId,
    uint requestId,
    uint requestCode,
    bytes memory responsePayload
  ) internal override
  { 
    emit ResponseArrived(
      caller,
      chainId,
      requestId,
      requestCode,
      responsePayload
    );
  }
}