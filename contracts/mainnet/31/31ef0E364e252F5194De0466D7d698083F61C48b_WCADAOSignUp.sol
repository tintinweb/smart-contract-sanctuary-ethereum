/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/WCADAOSignUp.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract WCADAOSignUp is Ownable {
	struct User {
		string username;
		address[] addresses;
	}

	mapping(string => address[]) public userToAddresses;
	mapping(address => string) public addressToUser;
	string[] public usernames;

	string public constant version = "0.1";

	constructor() {}

	function signUp(string memory username) external {
		username = lower(username);
		require(isValidUsername(username), "Username isn't valid, use only a-z, 0-9, . or -");
		require(userToAddresses[username].length == 0, "Username is unavaiable");
		require(bytes(addressToUser[msg.sender]).length == 0, "Wallet is already linked to another user");

		usernames.push(username);
		userToAddresses[username].push(msg.sender);
		addressToUser[msg.sender] = username;
	}

	function linkWalletTo(string memory username) external {
		username = lower(username);
		require(bytes(username).length > 0 && userToAddresses[username].length > 0, "Username doesn't exists");
		require(bytes(addressToUser[msg.sender]).length == 0, "Wallet already linked");

		userToAddresses[username].push(msg.sender);
		addressToUser[msg.sender] = username;
	}

	function unlinkWallet(address wallet) external {
		string memory username = addressToUser[msg.sender];
		require(bytes(username).length > 0, "You are not signed in DAO");
		require(wallet != address(0) && compare(addressToUser[wallet], username), "This wallet isn't linked to your username");
		require(userToAddresses[username].length > 1, "You should keep at least one wallet linked");
		removeWallet(userToAddresses[username], wallet);
		delete addressToUser[wallet];
	}

	function unsubscribe() external {
		string memory username = addressToUser[msg.sender];
		deleteUser(username);
	}

	function kick(string memory username) external onlyOwner {
		username = lower(username);
		require(userToAddresses[username].length > 0, "Username doesn't exists");
		deleteUser(username);
	}

	function deleteUser(string memory username) internal {
		for (uint256 i = 0; i < userToAddresses[username].length; i++) {
			delete addressToUser[userToAddresses[username][i]];
		}

		for (uint256 i = 0; i < usernames.length; i++) {
			if (compare(usernames[i], username)) {
				usernames[i] = usernames[usernames.length - 1];
				usernames.pop();
				break;
			}
		}

		delete userToAddresses[username];
	}

	function getUser(string memory username) external view returns (User memory user) {
		username = lower(username);
		require(userToAddresses[username].length > 0, "Username doesn't exists");

		return User(username, userToAddresses[username]);
	}

	function getUserFromAddress(address wallet) external view returns (User memory user) {
		require(bytes(addressToUser[wallet]).length > 0, "Wallet isn't linked to any user");

		return User(addressToUser[wallet], userToAddresses[addressToUser[wallet]]);
	}

	function getUsers() external view returns (User[] memory) {
		User[] memory users = new User[](usernames.length);
		for (uint256 i = 0; i < usernames.length; i++) {
			users[i] = User(usernames[i], userToAddresses[usernames[i]]);
		}
		return users;
	}

	function getUsersCount() external view returns (uint256) {
		return usernames.length;
	}

	function getUserAddressesCount(string calldata username) external view returns (uint256) {
		return userToAddresses[username].length;
	}

	function lower(string memory _base) internal pure returns (string memory) {
		bytes memory _baseBytes = bytes(_base);
		for (uint256 i = 0; i < _baseBytes.length; i++) {
			_baseBytes[i] = _lower(_baseBytes[i]);
		}
		return string(_baseBytes);
	}

	function _lower(bytes1 _b1) private pure returns (bytes1) {
		if (_b1 >= 0x41 && _b1 <= 0x5A) {
			return bytes1(uint8(_b1) + 32);
		}

		return _b1;
	}

	function compare(string memory s1, string memory s2) internal pure returns (bool) {
		return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
	}

	function removeWallet(address[] storage array, address wallet) internal returns (bool) {
		for (uint256 i = 0; i < array.length; i++) {
			if (array[i] == wallet) {
				array[i] = array[array.length - 1];
				array.pop();
				return true;
			}
		}
		return false;
	}

	function isValidUsername(string memory _base) internal pure returns (bool) {
		bytes memory _bytes = bytes(_base);
		if (_bytes.length < 1) {
			return false;
		}
		for (uint256 i = 0; i < _bytes.length; i++) {
			if (!((_bytes[i] >= 0x30 && _bytes[i] <= 0x39) || (_bytes[i] >= 0x61 && _bytes[i] <= 0x7a) || (_bytes[i] >= 0x2d && _bytes[i] <= 0x2e))) {
				return false;
			}
		}
		return true;
	}
}