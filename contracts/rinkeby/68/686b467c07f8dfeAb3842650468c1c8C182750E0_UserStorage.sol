//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/BaseStorage.sol";
import "./interfaces/IUserStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract UserStorage is BaseStorage, IUserStorage {
    event UserCreated(
        address indexed _userAddr,
        uint256 _userId,
        uint256 _timestamp
    );
    event UserDeleted(
        address indexed _userAddr,
        uint256 _userId,
        uint256 _timestamp
    );

    // Use for assigning unique ids to users
    using Counters for Counters.Counter;
    Counters.Counter private _userCount;

    // Map of user address to user profile
    mapping(address => Profile) public profiles;

    // Map of user's id to the the index of the user in the array of users
    mapping(uint256 => uint256) private _userIndex;

    // Store all user's id for easy enumeration
    uint256[] private _allUserIds;

    struct Profile {
        uint256 userId;
        address userAddr;
        bytes32 username;
        string image_uri;
        bool deleted;
    }

    function _exists(address _userAddr)
        public
        view
        onlyController
        returns (bool)
    {
        return profiles[_userAddr].userId > 0;
    }

    function createUser(
        address _userAddr,
        bytes32 _username,
        string memory _image_uri
    ) external onlyController returns (uint256) {
        _userCount.increment();
        uint256 newUserId = _userCount.current();
        profiles[_userAddr] = Profile(
            newUserId,
            _userAddr,
            _username,
            _image_uri,
            false
        );
        _allUserIds.push(newUserId);
        _userIndex[newUserId] = _allUserIds.length - 1;
        emit UserCreated(_userAddr, newUserId, block.timestamp);
        return newUserId;
    }

    function updateUserProfile(
        address _userAddr,
        bytes32 _username,
        string memory _image_uri
    ) external onlyController returns (uint256) {
        Profile memory profile = profiles[_userAddr];
        profile.username = _username;
        profile.image_uri = _image_uri;
        profiles[_userAddr] = profile;
        return profiles[_userAddr].userId;
    }

    function deleteUser(address _from) external onlyController {
        uint256 userId = profiles[_from].userId;
        uint256 lastIndex = _allUserIds.length - 1;
        uint256 userIndex = _userIndex[userId];
        _allUserIds[userIndex] = _allUserIds[lastIndex];
        _userIndex[_allUserIds[lastIndex]] = userIndex;
        _allUserIds.pop();
        delete profiles[_from];
        profiles[_from].deleted = true;

        emit UserDeleted(_from, userId, block.timestamp);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBaseStorage.sol";

contract BaseStorage is Ownable, IBaseStorage {
    address public controllerAddr;

    modifier onlyController() {
        require(msg.sender == controllerAddr);
        _;
    }

    function setControllerAddr(address _controllerAddr) public onlyOwner {
        controllerAddr = _controllerAddr;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUserStorage {
    function profiles(address _userAddr)
        external
        view
        returns (
            uint256 userId,
            address userAddr,
            bytes32 username,
            string memory image_uri,
            bool deleted
        );

    function _exists(address) external view returns (bool);

    function createUser(
        address _userAddr,
        bytes32 _username,
        string memory _image_uri
    ) external returns (uint256);

    function updateUserProfile(
        address _userAddr,
        bytes32 _username,
        string memory _image_uri
    ) external returns (uint256);

    function deleteUser(address) external;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBaseStorage {
    function controllerAddr() external view returns (address);

    function setControllerAddr(address _controllerAddr) external;
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