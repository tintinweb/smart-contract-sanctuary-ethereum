//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenRegistry is Ownable,Pausable {
	// Contract name
    string private _name;

	struct Token {
		address addr;
		uint decimals;
		string name;
		string symbol;
		bool deleted;
	}

	event Registered(uint indexed id, address addr, string name, string symbol);
	event Unregistered(uint indexed id, string symbol);

	mapping (address => uint) mapFromAddress;
	mapping (string => uint) mapFromSymbol;
	Token[] tokens;
	uint public fee = 2000000000000000000; // 2 eth
	uint public tokenCount = 0;

    function name() public view virtual returns (string memory) {
        return _name;
    }

	modifier whenFeePaid {
		if (msg.value < fee)
			return;
		_;
	}

	modifier whenAddressFree(address _addr) {
		if (isRegistered(_addr))
			return;
		_;
	}

	modifier whenSymbolFree(string memory _symbol) {
		if (mapFromSymbol[_symbol] != 0)
			return;
		_;
	}

	modifier isValidSymbol(string memory _symbol) {
		if (bytes(_symbol).length < 3 || bytes(_symbol).length > 4)
			return;
		_;
	}

	modifier whenToken(uint _id) {
		require(!tokens[_id].deleted);
		_;
	}

	constructor (){
		_name = "CV Token registy v1";
	}

	function register(
		address addr_,
		string memory symbol_,
		uint decimals_,
		string memory name_
	)
		external
		payable
		returns (bool)
	{
		return registerAs(
			addr_,
			symbol_,
			decimals_,
			name_
		);
	}

    function togglePause() public onlyOwner{
        if(this.paused()){
            _unpause();
        }else{
            _pause();
        }
    }

	function unregister(uint _id)
		external
		whenToken(_id)
		onlyOwner
	{
		delete mapFromAddress[tokens[_id].addr];
		delete mapFromSymbol[tokens[_id].symbol];
		tokens[_id].deleted = true;
		tokenCount = tokenCount - 1;

        emit Unregistered(_id, tokens[_id].symbol);
	}

	function setFee(uint _fee)
		external
		onlyOwner
	{
		fee = _fee;
	}

	function drain()
		external
		onlyOwner
	{
		payable(msg.sender).transfer(address(this).balance);
	}

	function token(uint _id)
		external
		view
		whenToken(_id)
		returns (
			address addr,
			string memory symbol,
			uint decimals,
			string memory name_
		)
	{
		Token storage t = tokens[_id];
		addr = t.addr;
		symbol = t.symbol;
		decimals = t.decimals;
		name_ = t.name;
	}

	function fromAddress(address _addr)
		external
		view
		whenToken(mapFromAddress[_addr] - 1)
		returns (
			uint id_,
			string memory symbol_,
			uint decimals_,
			string memory name_
		)
	{
		id_ = mapFromAddress[_addr] - 1;
		Token storage t = tokens[id_];
		symbol_ = t.symbol;
		decimals_ = t.decimals;
		name_ = t.name;
	}

	function fromSymbol(string memory _symbol)
		external
		view
		whenToken(mapFromSymbol[_symbol] - 1)
		returns (
			uint id_,
			address addr_,
			uint decimals_,
			string memory name_
		)
	{
		id_ = mapFromSymbol[_symbol] - 1;
		Token storage t = tokens[id_];
		addr_ = t.addr;
		decimals_ = t.decimals;
		name_ = t.name;
	}

	function registerAs(
		address addr_,
		string memory symbol_,
		uint decimals_,
		string memory name_
	)
		public
		payable
        whenNotPaused
		whenFeePaid
		whenAddressFree(addr_)
		isValidSymbol(symbol_)
		whenSymbolFree(symbol_)
		returns (bool)
	{
		tokens.push(Token(
			addr_,
            decimals_,
			symbol_,
			name_,
            false
		));
        uint length = tokens.length;
		mapFromAddress[addr_] = length;
		mapFromSymbol[symbol_] = length;

		emit Registered(
            tokens.length - 1,
			addr_,
			name_,
            symbol_
		);

		tokenCount = tokenCount + 1;
		return true;
	}

    function isRegistered(address _address) public view returns(bool) {
        if (mapFromAddress[_address] == 0) {
			return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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