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
pragma solidity ^0.8.0;

import "./Utils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserInfo is Utils, Ownable {
    User[] public users;
    uint256 public count;
    Activity[] public activities;
    Transaction[] public transactions;
    address[] public whitelist;
    mapping(address => bool) public isWhitelisted;

    /*====================================================================================
                                User Methods
    ====================================================================================*/
    function addUser(User memory _user) external onlyOwner returns (bool) {
        for (uint256 index = 0; index < users.length; index++) {
            if (msg.sender == users[index]._address) {
                setActivity(
                    Activity(
                        msg.sender,
                        0,
                        0,
                        0,
                        block.timestamp,
                        "Update User"
                    )
                );
                users[index] = _user;
                return true;
            }
        }
        users.push(_user);
        count++;
        setActivity(Activity(msg.sender, 0, 0, 0, block.timestamp, "Add User"));
        emit CreateUser(
            _user._address,
            _user._fullName,
            _user._adhaar,
            _user._pan,
            _user._phoneNumber
        );
        return true;
    }

    function getUser(address _address) public view returns (User memory) {
        User memory _user;
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i]._address == _address) {
                _user = users[i];
            }
        }
        return _user;
    }

    function getUsersList() public view returns (User[] memory) {
        uint256 _length = users.length;
        User[] memory _users = new User[](_length);
        for (uint256 i = 0; i < _length; i++) {
            _users[i] = users[i];
        }
        return _users;
    }

    function setActivity(Activity memory _activity) public {
        activities.push(_activity);
    }

    function setTransaction(Transaction memory _transaction) public {
        transactions.push(_transaction);
    }

    function get_activities() public view returns (Activity[] memory) {
        uint256 length = activities.length;
        Activity[] memory _activities = new Activity[](length);
        for (uint256 i = 0; i < length; i++) {
            _activities[i] = activities[i];
        }
        return _activities;
    }

    function get_transactions() public view returns (Transaction[] memory) {
        uint256 length = transactions.length;
        Transaction[] memory _transactions = new Transaction[](length);
        for (uint256 i = 0; i < length; i++) {
            _transactions[i] = transactions[i];
        }
        return _transactions;
    }

    /*====================================================================================
                                Whitelist Methods
    ====================================================================================*/
    function addToWhitelist(
        address _address
    ) external onlyOwner returns (bool) {
        whitelist.push(_address);
        setActivity(
            Activity(msg.sender, 0, 0, 0, block.timestamp, "Added to Whitelist")
        );
        return true;
    }

    function getWhitelist() public view returns (address[] memory) {
        address[] memory _whitelist = new address[](whitelist.length);
        for (uint256 i = 0; i < whitelist.length; i++) {
            _whitelist[i] = whitelist[i];
        }
        return _whitelist;
    }

    function removeFromWhitelist(address _address) public returns (bool) {
        for (uint256 index = 0; index < whitelist.length; index++) {
            if (whitelist[index] == _address) {
                delete whitelist[index];
                setActivity(
                    Activity(
                        msg.sender,
                        0,
                        0,
                        0,
                        block.timestamp,
                        "Removed from Whitelist"
                    )
                );
                return true;
            }
        }
        return false;
    }

    function removeTransaction(uint256 _id) public {
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i]._id == _id) {
                delete transactions[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

contract Utils {
    struct Token {
        address _creator;
        address _owner;
        uint256 _price;
        uint256 _royality;
        uint256 _commission;
        string _tokenURI;
    }

    struct Sender {
        address _address;
        string _name;
        string _avatar;
    }

    struct NFTTransactions {
        Sender from;
        Sender to;
        uint256 time;
        uint256 price;
    }

    struct User {
        address _address;
        string _fullName;
        string _email;
        string _pan;
        string _adhaar;
        string _phoneNumber;
        string _facebok;
        string _twitter;
        string _instagram;
        string _header;
        string _avatar;
    }

    struct Activity {
        address _address;
        uint256 _price;
        uint256 _royality;
        uint256 _commission;
        uint256 _time;
        string _status;
    }

    struct Transaction {
        Sender _from;
        Sender _to;
        uint256 _id;
        uint256 _price;
        uint256 _time;
    }

    event CreateUser(
        address _address,
        string _fullName,
        string _email,
        string _pan,
        string _phoneNumber
    );

    function compare(
        string memory _a,
        string memory _b
    ) public pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }
}