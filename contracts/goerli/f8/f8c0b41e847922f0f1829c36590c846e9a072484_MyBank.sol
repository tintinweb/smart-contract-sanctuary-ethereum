/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


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

// File: SimpleBank.sol


pragma solidity ^0.8.0;

// import "xxxx";


contract MyBank is Ownable {
    mapping (address => uint256) public balances;

    address[] public accounts;
    uint256 rate = 50; // 50% per year

    function deposit() public payable {
        if (balances[msg.sender] == 0) {
            accounts.push(msg.sender);
        }
        balances[msg.sender] += msg.value;
    }

    // 1.5
    // balances[B] = 1.5
    // balances[B] = 1.5 - 1.5 = 0
    function withdraw(uint256 amount) public returns (uint256) {
        require(balances[msg.sender] >= amount, "balance is not enough");
        balances[msg.sender] -= amount; // 3

        payable(msg.sender).transfer(amount); // transfer 1.5 -> B

        return balances[msg.sender];
    }

    function usersCount() public view returns (uint256 count) {
        count = accounts.length;
    }

    // Only admin can call (invoke)
    // admin need to deposit interest -> system
    function increaseYear()
        public
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = balances[account] * rate / 100;
            balances[account] += interest;
        }
    }

    // only admin can withdraw for any amount
    function systemWithdraw(uint256 amount)
        public
        onlyOwner
    {
        payable(msg.sender).transfer(amount);
    }

}