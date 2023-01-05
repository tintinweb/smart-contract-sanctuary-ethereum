//
//  ___  __    ________  ________ ___          ________ ________  ________ _________  ________  ________      ___    ___
// |\  \|\  \ |\   __  \|\  _____\\  \        |\  _____\\   __  \|\   ____\\___   ___\\   __  \|\   __  \    |\  \  /  /|
// \ \  \/  /|\ \  \|\  \ \  \__/\ \  \       \ \  \__/\ \  \|\  \ \  \___\|___ \  \_\ \  \|\  \ \  \|\  \   \ \  \/  / /
//  \ \   ___  \ \  \\\  \ \   __\\ \  \       \ \   __\\ \   __  \ \  \       \ \  \ \ \  \\\  \ \   _  _\   \ \    / /
//   \ \  \\ \  \ \  \\\  \ \  \_| \ \  \       \ \  \_| \ \  \ \  \ \  \____   \ \  \ \ \  \\\  \ \  \\  \|   \/  /  /
//    \ \__\\ \__\ \_______\ \__\   \ \__\       \ \__\   \ \__\ \__\ \_______\  \ \__\ \ \_______\ \__\\ _\ __/  / /
//     \|__| \|__|\|_______|\|__|    \|__|        \|__|    \|__|\|__|\|_______|   \|__|  \|_______|\|__|\|__|\___/ /
//                                                                                                          \|___|/
//
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Kofi.sol";

contract KofiFactory is Ownable {
	// List of all parent kofies.
	address[] private kofiParents;

	// Investor fee.
	uint256 public investorFee;

	// Events.
	event UpdateInvestorFee(uint256 investorFee);
	event NewFactory(address owner, address kofiShop);
	event NewFactoryFromInvestor(
		address investor,
		address kofiShop,
		uint256 amount
	);

	constructor() {
		investorFee = 10 ether;
	}

	/**
	 * @dev fetches all stored parent addresses
	 */
	function getKofiParents() public view returns (address[] memory) {
		return kofiParents;
	}

	/**
	 * @dev sets investor fee
	 */
	function setInvestorFee(uint256 _fee) external onlyOwner {
		investorFee = _fee;

		emit UpdateInvestorFee(_fee);
	}

	/**
	 * @dev create kofi child contract for 1k users
	 */
	function create() external onlyOwner {
		Kofi kofi = new Kofi(owner(), address(0));
		kofiParents.push(address(kofi));

		emit NewFactory(owner(), address(kofi));
	}

	/**
	 * @dev create kofi child contract for 1k users with payment
	 */
	function createAndSendEther() external payable {
		require(msg.value >= investorFee, "can't create for free!");

		Kofi kofi = (new Kofi){ value: msg.value }(owner(), msg.sender);
		kofiParents.push(address(kofi));

		emit NewFactoryFromInvestor(msg.sender, address(kofi), msg.value);
	}

	/**
	 * @dev send the entire balance stored in this contract to the owner
	 */
	function withdrawTips() external onlyOwner {
		(bool success, ) = owner().call{ value: address(this).balance }("");

		require(success, "failed to withdraw!");
	}
}

//
//  ___  __    ________  ________ ___          ________  ___  ___  ________  ________
// |\  \|\  \ |\   __  \|\  _____\\  \        |\   ____\|\  \|\  \|\   __  \|\   __  \
// \ \  \/  /|\ \  \|\  \ \  \__/\ \  \       \ \  \___|\ \  \\\  \ \  \|\  \ \  \|\  \
//  \ \   ___  \ \  \\\  \ \   __\\ \  \       \ \_____  \ \   __  \ \  \\\  \ \   ____\
//   \ \  \\ \  \ \  \\\  \ \  \_| \ \  \       \|____|\  \ \  \ \  \ \  \\\  \ \  \___|
//    \ \__\\ \__\ \_______\ \__\   \ \__\        ____\_\  \ \__\ \__\ \_______\ \__\
//     \|__| \|__|\|_______|\|__|    \|__|       |\_________\|__|\|__|\|_______|\|__|
//                                               \|_________|
//
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Kofi is Ownable, Pausable {
	// Memo struct.
	struct Memo {
		address from;
		string name;
		string title;
		string message;
		uint256 stars;
	}

	// User struct.
	struct User {
		address wallet;
		string name;
		string username;
	}

	// List of all registered users.
	User[] private users;

	// User check.
	mapping(address => bool) private blackList;
	mapping(address => bool) private uniqueUserCheck;
	mapping(string => bool) private uniqueUsernameCheck;

	// List of all memos received from coffee purchases.
	mapping(address => Memo[]) private memos; // max 10 memos

	// Fees.
	uint256 public registrationFee; // user registration fee
	uint256 public buyCoffeeFee; // buy coffee platform fee
	uint256 public coffeePrice; // min coffee price for buyer

	// Max user.
	uint256 public userCountMax;

	// Investor.
	address public investor;

	// Event to emit when a User is created.
	event NewUser(
		address indexed user,
		uint256 timestamp,
		string name,
		string username
	);

	// Event to emit when a User is updated.
	event UpdateUser(
		address indexed user,
		uint256 timestamp,
		string name,
		string username
	);

	// Event to emit when a Memo is created.
	event NewMemo(
		address indexed from,
		address user,
		uint256 timestamp,
		string name,
		string title,
		string message,
		uint256 stars
	);

	// Event to emit when buying a cup of coffee.
	event NewCoffee(
		address indexed from,
		address user,
		uint256 timestamp,
		uint256 price
	);

	// Event to set fees.
	event UpdateRegistrationFee(uint256 registrationFee);
	event UpdateBuyCoffeeFee(uint256 buyFee);
	event UpdateCoffeePrice(uint256 coffeePrice);

	// Event to update userCountMax
	event UpdateUserCountMax(uint256 max);

	// Event to ban a user.
	event NewBannedUser(address user, bool ban);

	// Event to remove a bad memo.
	event DeleteMemo(uint256 memoId, address user);

	constructor(address _owner, address _investor) payable {
		// Store the address of the deployer as a payable address.
		// When we withdraw funds, we'll withdraw here.
		_transferOwnership(_owner);
		registrationFee = 0.05 ether;
		buyCoffeeFee = 0.005 ether;
		coffeePrice = 0.02 ether;
		userCountMax = 1000;
		investor = _investor;
	}

	/**
	 * @dev fetches all stored users
	 */
	function getUsers() public view returns (User[] memory) {
		return users;
	}

	/**
	 * @dev fetches all stored memos for a user
	 */
	function getMemos(address _user) public view returns (Memo[] memory) {
		return memos[_user];
	}

	/**
	 * @dev checks if the user is blacklisted
	 */
	function isBlackListed(address _user) public view returns (bool) {
		return blackList[_user];
	}

	/**
	 * @dev register a user
	 * @param _name name of the coffee user
	 * @param _username unique id for a user
	 */
	function register(string memory _name, string memory _username)
		public
		payable
		whenNotPaused
	{
		// Must accept more than "registrationFee" for registration.
		require(msg.value >= registrationFee, "can't register for free!");

		// Must have 1k users only.
		require(users.length < userCountMax, "user limit!");

		// Must have unique username.
		require(
			!uniqueUsernameCheck[_username],
			"username already registered!"
		);

		// 1 user per address
		require(!uniqueUserCheck[msg.sender], "user already registered!");

		// send 30% immediately to investor.
		if (investor != address(0)) {
			(bool success, ) = investor.call{ value: (msg.value / 10) * 3 }("");

			require(success, "failed to withdraw to investor!");
		}

		// Add the user to storage.
		users.push(User(msg.sender, _name, _username));

		uniqueUserCheck[msg.sender] = true;
		uniqueUsernameCheck[_username] = true;

		// Emit a NewUser event with details.
		emit NewUser(msg.sender, block.timestamp, _name, _username);
	}

	function updateUser(
		uint256 _index,
		string memory _name,
		string memory _username
	) public {
		// Must have unique username.
		require(
			!uniqueUsernameCheck[_username],
			"username already registered!"
		);

		// User must be registered.
		require(uniqueUserCheck[msg.sender], "not registered user!");

		// Sender must be a user with _index
		require(users[_index].wallet == msg.sender, "not correct user!");

		uniqueUsernameCheck[users[_index].username] = false;
		users[_index].name = _name;
		users[_index].username = _username;
		uniqueUsernameCheck[_username] = true;

		// Emit a UpdateUser event with details.
		emit UpdateUser(msg.sender, block.timestamp, _name, _username);
	}

	/**
	 * @dev buy a coffee for a user (sends an ETH tip and leaves a memo)
	 * @param _name name of the coffee purchaser
	 * @param _title title of the coffee purchaser
	 * @param _message a nice message from the purchaser
	 * @param _stars a nice rate from the purchaser
	 */
	function buyCoffee(
		address _user,
		string memory _name,
		string memory _title,
		string memory _message,
		uint256 _stars
	) public payable whenNotPaused {
		// Must accept more than "coffeePrice" for a coffee.
		require(msg.value >= coffeePrice, "can't buy coffee for free!");

		// Must not be a banned user.
		require(blackList[_user] != true, "user is banned!");

		// Send coffee to user.
		(bool success, ) = _user.call{ value: msg.value - buyCoffeeFee }("");
		require(success, "failed to send ether!");

		// send 50% fee immediately to investor.
		if (investor != address(0)) {
			(bool successInvestor, ) = investor.call{
				value: (buyCoffeeFee / 10) * 5
			}("");

			require(successInvestor, "failed to withdraw to investor!");
		}

		// Must have less than 10 memos.
		if (memos[_user].length < 10) {
			// Add the memo to storage!
			memos[_user].push(
				Memo(msg.sender, _name, _title, _message, _stars)
			);

			// Emit a NewMemo event with details about the memo.
			emit NewMemo(
				msg.sender,
				_user,
				block.timestamp,
				_name,
				_title,
				_message,
				_stars
			);
		}

		// Emit a NewCoffee event with details.
		emit NewCoffee(msg.sender, _user, block.timestamp, msg.value);
	}

	/// Owner functions
	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}

	/**
	 * @dev removes bad memo upon request
	 * @param _index the memo id to remove
	 */
	function deleteMemo(uint256 _index, address _user) external onlyOwner {
		// Move the last memo into the place to delete
		memos[_user][_index] = memos[_user][memos[_user].length - 1];
		// Remove the last element
		memos[_user].pop();

		// Emit a DeleteMemo event
		emit DeleteMemo(_index, _user);
	}

	/**
	 * @dev sets fee of user registration
	 * @param _fee registration fee
	 */
	function setRegistrationFee(uint256 _fee) external onlyOwner {
		registrationFee = _fee;

		// Emit a registrationFee update event.
		emit UpdateRegistrationFee(_fee);
	}

	/**
	 * @dev sets tip for waitress
	 * @param _fee buy coffee fee
	 */
	function setBuyCoffeeFee(uint256 _fee) external onlyOwner {
		buyCoffeeFee = _fee;

		// Emit a buyCoffeeFee update event.
		emit UpdateRegistrationFee(_fee);
	}

	/**
	 * @dev sets coffee price
	 * @param _price price of a cup of coffee
	 */
	function setCoffeePrice(uint256 _price) external onlyOwner {
		coffeePrice = _price;

		// Emit a registrationFee update event.
		emit UpdateCoffeePrice(_price);
	}

	/**
	 * @dev sets max user count
	 * @param _max user count
	 */
	function setUserCountMax(uint256 _max) external onlyOwner {
		userCountMax = _max;

		// Emit a userCountMax update event.
		emit UpdateUserCountMax(_max);
	}

	/**
	 * @dev sets banned user
	 * @param _address address of banned user
	 * @param _ban true or false
	 */
	function setBlackList(address _address, bool _ban) external onlyOwner {
		blackList[_address] = _ban;

		// Emit setBlackList event.
		emit NewBannedUser(_address, _ban);
	}

	/**
	 * @dev send the entire balance stored in this contract to the owner
	 */
	function withdrawAll() external onlyOwner {
		(bool success, ) = owner().call{ value: address(this).balance }("");

		require(success, "failed to withdraw!");
	}

	/**
	 * @dev compare two strings
	 * @param _str1 first string to compare
	 * @param _str2 second string to compare
	 */
	function compare(string memory _str1, string memory _str2)
		internal
		pure
		returns (bool)
	{
		if (bytes(_str1).length != bytes(_str2).length) {
			return false;
		}
		return
			keccak256(abi.encodePacked(_str1)) ==
			keccak256(abi.encodePacked(_str2));
	}
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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