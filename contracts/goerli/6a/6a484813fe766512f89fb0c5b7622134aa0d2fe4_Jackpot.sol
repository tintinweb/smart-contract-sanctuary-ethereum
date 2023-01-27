/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// File: Interface/IERC20.sol



pragma solidity ^0.8.4;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(address account, uint256 amount) external;
}

// File: Library/EnumerableSet.sol



pragma solidity ^0.8.4;

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
// File: Library/Verify.sol



pragma solidity ^0.8.16;


abstract contract Verify {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(string => bool) public VERIFY_MESSAGE;
    EnumerableSet.AddressSet private OPERATOR;

    modifier onlyOperator() {
        require(OPERATOR.contains(msg.sender), "NOT OPERATOR.");
        _;
    }

    modifier verifySignature(string memory message, uint8 v, bytes32 r, bytes32 s) {
        require(checkVerifySignature(message, v, r, s), "INVALID SIGNATURE.");
        _;
    }

    constructor() internal {
        OPERATOR.add(msg.sender);
    }

    modifier rejectDoubleMessage(string memory message) {
        require(!VERIFY_MESSAGE[message], "SIGNATURE ALREADY USED.");
        _;
    }

    function checkVerifySignature(string memory message, uint8 v, bytes32 r, bytes32 s) public view returns(bool) {
        return OPERATOR.contains(verifyString(message, v, r, s));
    }

    function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) private pure returns(address signer){
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length:= mload(message)
            lengthOffset:= add(header, 57)
        }
        require(length <= 999999, "NOT PROVIDED.");
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    function getOperator() external view returns (address[] memory) {
        return OPERATOR.values();
    }

    function updateOperator(address _operatorAddr, bool _flag) public onlyOperator {
        require(_operatorAddr != address(0), "ZERO ADDRESS.");
        if (_flag) {
            OPERATOR.add(_operatorAddr);
        } else {
            OPERATOR.remove(_operatorAddr);
        }
    }
}
// File: Library/TransferHelper.sol



pragma solidity ^0.8.4;

/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeBurn(
        address token,
        address from,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x9dc29fac, from, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeBurn: BURN_FAILED"
        );
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeMintNFT(
        address token,
        address to,
        string memory uri
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xd204c45e, to, uri)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: MINT_NFT_FAILED"
        );
    }

    function safeApproveForAll(
        address token,
        address to,
        bool value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa22cb465, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    // sends ETH or an erc20 token
    function safeTransferBaseToken(
        address token,
        address payable to,
        uint256 value,
        bool isERC20
    ) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper: TRANSFER_FAILED"
            );
        }
    }
}

// File: Library/Context.sol



pragma solidity ^0.8.4;

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

// File: Library/Ownable.sol



pragma solidity ^0.8.4;


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
// File: Main/Jackpot.sol


pragma solidity ^0.8.4;





contract Jackpot is Ownable, Verify {
    address public admin;
    mapping(uint256 => Jackpot) public jackpots;
    mapping(uint256 => User[]) public users;
    mapping(string => bool) private verifyMessage;

    event CreateJackpot(uint256 indexed jackpotId, User[] users, uint256 amount, address addressToken);

    event UpdateWinner(uint256 indexed jackpotId, User[] users, uint256 amount, uint256 userIdWinner, address addressWinner);

    event ClaimToken(address indexed caller, uint256 amount, uint256 jackpotId, uint256 userId);

    event Test(address indexed caller, uint256 jackpotId, uint256 userId);

    enum JACKPOT_STATUS {
        OPENED,
        CLOSED,
        CLAIMED
    }

    struct User{
        uint256 userId;
        uint256 rate;
        address userAddress;
    }

    struct Jackpot{
        uint256 jackpotId;
        uint256 amount;
        address addressToken;
        uint256 userIdWinner;
        address addressWinner;
        JACKPOT_STATUS jackpotStatus; 
    }

    function createJackpot(
        uint256 _jackpotId, 
        User[] memory _users, 
        uint256 _amount, 
        address _addressToken,
        string memory message,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external onlyOperator rejectDoubleMessage(message){
        require(checkVerifySignature(message, v, r, s), "INVALID SIGNATURE.");
        require(jackpots[_jackpotId].addressToken == address(0), "JACKPOT ALREADY EXIST.");
        require(_amount > 0, "AMOUNT MUST BE GREATER THAN 0.");
        require(_addressToken != address(0), "INVALID TOKEN ADDRESS.");

        for (uint256 i = 0; i < _users.length; i++) {
            require(
                _users[i].userAddress != address(0), 
                "INVALID TOKEN ADDRESS."
            );
   
            users[_jackpotId].push(
                User(
                    _users[i].userId, 
                    _users[i].rate, 
                    _users[i].userAddress
                )
            );
        } 

        jackpots[_jackpotId] = Jackpot(
            _jackpotId, 
            _amount, 
            _addressToken, 
            0,
            address(0), 
            JACKPOT_STATUS.OPENED
        );

        TransferHelper.safeTransferFrom(
            _addressToken,
            msg.sender,
            address(this),
            _amount
        );

        VERIFY_MESSAGE[message] = true;

        emit CreateJackpot(_jackpotId, _users, _amount, _addressToken);
    }

    function updateWinner(
        uint256 _jackpotId, 
        User[] memory _users, 
        uint256 _amount,
        uint256 _userIdWinner,
        string memory message,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external onlyOperator rejectDoubleMessage(message){
        require(checkVerifySignature(message, v, r, s), "INVALID SIGNATURE.");
        require(jackpots[_jackpotId].addressToken != address(0), "INVALID JACKPOT ID.");
        require(_amount > 0, "AMOUNT MUST BE GREATER THAN 0.");
        require(
            jackpots[_jackpotId].jackpotStatus == JACKPOT_STATUS.OPENED, 
            "INVALID TIME TO UPDATE WINNER."
        );
        
        delete users[_jackpotId];

        bool idUserExist;
        uint256 indexWinner;
        for (uint256 i = 0; i < _users.length; i++) {
            if(_users[i].userId == _userIdWinner) {
                idUserExist = true;
                indexWinner = i;
                break;
            }
        }
        require(idUserExist, "USER ID WINNER NOT EXIST.");

        for (uint256 i = 0; i < _users.length; i++) {
            require(_users[i].userAddress != address(0), "INVALID TOKEN ADDRESS.");
            User memory user = User(_users[i].userId, _users[i].rate, _users[i].userAddress);
            users[_jackpotId].push(user);
        }
        uint256 jackpotId = _jackpotId;
        if(jackpots[jackpotId].amount < _amount) {
            TransferHelper.safeTransferFrom(
                jackpots[jackpotId].addressToken,
                msg.sender,
                address(this),
                _amount - jackpots[jackpotId].amount
            );
        } else {
            TransferHelper.safeTransfer(
                jackpots[jackpotId].addressToken,
                msg.sender,
                jackpots[jackpotId].amount - _amount
            );
        }
        
        jackpots[jackpotId].userIdWinner = _userIdWinner;
        jackpots[jackpotId].addressWinner = users[jackpotId][indexWinner].userAddress;
        jackpots[jackpotId].amount = _amount;
        jackpots[jackpotId].jackpotStatus = JACKPOT_STATUS.CLOSED;

        VERIFY_MESSAGE[message] = true;
        
        emit UpdateWinner(jackpotId, _users, _amount, _userIdWinner, users[jackpotId][indexWinner].userAddress);
    }

    function claimToken(uint256 _jackpotId, uint256 _userIdWinner) external {
        require(jackpots[_jackpotId].addressToken != address(0), "INVALID JACKPOT ID.");
        require(
            jackpots[_jackpotId].jackpotStatus == JACKPOT_STATUS.CLOSED, 
            "INVALID TIME TO CLAIM TOKEN."
        );
        
        bool idUserExist;
        uint256 indexWinner;
        for (uint256 i = 0; i < users[_jackpotId].length; i++) {
            if(users[_jackpotId][i].userId == _userIdWinner) {
                idUserExist = true;
                indexWinner = i;
                break;
            }
        }
         require(idUserExist, "USER ID WINNER NOT EXIST.");

        require(
            jackpots[_jackpotId].addressWinner == users[_jackpotId][indexWinner].userAddress &&
            jackpots[_jackpotId].addressWinner == msg.sender,
            "ONLY WINNER ADDRESS CAN CALL."
        );

        TransferHelper.safeTransfer(
            jackpots[_jackpotId].addressToken,
            jackpots[_jackpotId].addressWinner,
            jackpots[_jackpotId].amount
        );

        jackpots[_jackpotId].jackpotStatus = JACKPOT_STATUS.CLAIMED;

        emit ClaimToken(msg.sender, jackpots[_jackpotId].amount, _jackpotId, _userIdWinner);
    }

    function test(uint256 _jackpotId, uint256 _userIdWinner) external {   
      
    
    emit Test(msg.sender,  _jackpotId, _userIdWinner);
    }
}