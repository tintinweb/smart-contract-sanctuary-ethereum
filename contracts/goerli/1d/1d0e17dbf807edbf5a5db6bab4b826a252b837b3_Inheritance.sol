/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
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

// Inheritance Contract

contract Inheritance is Ownable {

    // Struct to store user data
    struct User {
        address payable cefi_account;
        uint expiration;
        uint renewal_period_in_minutes;
        uint balance;
    }

    // Mapping from user addresses to their data
    mapping(address => User) users;

    // Allow contract to receive funds
    receive() external payable {}

    // Check cefi_account, time left, renewal period, and balance of the given user
    function view_details() public view returns (
        address payable cefi_account,
        uint time_left_in_seconds,
        uint renewal_period_in_minutes,
        uint balance) {
        // Calculate the time left if not already expired
        time_left_in_seconds = 0;
        if (block.timestamp < users[msg.sender].expiration) {
            time_left_in_seconds = (users[msg.sender].expiration - block.timestamp) * 1 seconds;
        }
        return (
            users[msg.sender].cefi_account,
            time_left_in_seconds,
            users[msg.sender].renewal_period_in_minutes,
            users[msg.sender].balance
        );
    }

    // Adds a cefi account address and renewal period for the given user
    function add_my_cefi(address payable cefi_account, uint renewal_period_in_minutes) public payable {
        // Ensure the user has not already added a cefi account
        require(users[msg.sender].cefi_account == address(0), "CeFi account already set for user");
        // Ensure the msg.value is not 0
        require(msg.value != 0, "Value must be greater than 0");
        // Set the cefi account, expiration, renewal period, and balance for the user
        users[msg.sender].cefi_account = cefi_account;
        users[msg.sender].expiration = block.timestamp + (renewal_period_in_minutes * 1 minutes);
        users[msg.sender].renewal_period_in_minutes = renewal_period_in_minutes;
        users[msg.sender].balance = msg.value / 1000000000000000000;
    }

    // Update cefi account address for the given user
    function update_cefi_account(address payable new_cefi_account) public {
        // Ensure the user has added a cefi account
        require(users[msg.sender].cefi_account != address(0), "CeFi account not set for user");
        // Ensure the user is still alive
        require(block.timestamp < users[msg.sender].expiration, "Too late ...");
        // Update the cefi account for the user
        users[msg.sender].cefi_account = new_cefi_account;
        // Update the expiration for the user
        users[msg.sender].expiration = block.timestamp + (users[msg.sender].renewal_period_in_minutes * 1 minutes);
    }

    // Update renewal period for the given user
    function update_renewal_period(uint new_renewal_period_in_minutes) public {
        // Ensure the user has added a cefi account
        require(users[msg.sender].cefi_account != address(0), "CeFi account not set for user");
        // Ensure the user is still alive
        require(block.timestamp < users[msg.sender].expiration, "Too late ...");
        // Update the renewal period for the user
        users[msg.sender].renewal_period_in_minutes = new_renewal_period_in_minutes;
        // Update the expiration for the user
        users[msg.sender].expiration = block.timestamp + (new_renewal_period_in_minutes * 1 minutes);
    }

    // Renews the expiration for the given user
    function im_alive() public {
        // Ensure the user has added a cefi account
        require(users[msg.sender].cefi_account != address(0), "CeFi account not set for user");
        // Ensure the user is still alive
        require(block.timestamp < users[msg.sender].expiration, "Too late ...");
        // Update the expiration for the user
        users[msg.sender].expiration = block.timestamp + (users[msg.sender].renewal_period_in_minutes * 1 minutes);
    }

    // Checks the expiration for the given user and sends the funds to cefi account if expired
    function dead(address payable disinherited) public payable onlyOwner {
        // Ensure the user has added a cefi account
        require(users[disinherited].cefi_account != address(0), "CeFi account not set for user");
        // Ensure the user is not dead
        require(block.timestamp >= users[disinherited].expiration, "Still alive ...");
        // Send the funds to the cefi account
        users[disinherited].cefi_account.transfer(users[disinherited].balance * 1 ether);
        // Delete the disinherited record
        delete users[disinherited];
    }
}