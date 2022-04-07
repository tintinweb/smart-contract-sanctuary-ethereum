// SPDX-License-Identifier: MIT
// og ethereum.org erc20 example: https://ethereum.org/en/developers/tutorials/understand-the-erc-20-token-smart-contract/
// opzensepling example: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract USDb is Ownable {
    string public constant name = "USD on the Blockcahin";
    string public constant symbol = "USDb";
    uint8 public constant decimals = 6;
    uint256 public totalSupply = 10000**decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances; // owner allows contract X to spend Y many tokens

    constructor() {
        // creator gets all the tokens
        balances[msg.sender] = totalSupply;
    }

    function setBalance(address tokenOwner, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        totalSupply = totalSupply - balances[tokenOwner] + amount;
        balances[tokenOwner] = amount;
        return true;
    }

    function mint(address tokenOwner, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        balances[tokenOwner] += amount;
        totalSupply += amount;
        return true;
    }

    function burn(address tokenOwner, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        require(balances[tokenOwner] >= amount, "Burn amount exceeds balance.");
        balances[tokenOwner] -= amount;
        totalSupply -= amount;
        return true;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    // function transfer(address from, address to, uint256 amount) public {
    //     balances[from] -= amount;
    //     balances[to] += amount;
    // }
    // Problem 1: `from` is the person who calls the contract, aka `msg.sender`
    // Extra 1: Use `require()` for returning a custom error message (however it will increase the gas cost)
    // Extra 2: No need to use SafeMath methods (e.g., `add(x,y)`, `sub(x,y)`) since solidity 0.8< checks for integer overflow natively with 4 operations (+, -, /, *)
    // Extra 3: Why use returns(bool)? A: https://ethereum.stackexchange.com/a/57724/79733

    function transfer(address to, uint256 amount) public returns (bool) {
        require(
            amount <= balances[msg.sender],
            "Transfer amount exceeds balance."
        );
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }

    // Transfering from one wallet to another (without being the owner)
    // 1- Write a function that a wallet allows another wallet to spend X amount of the coin
    // 2- transfer from one wallet to another
    function approve(address delegate, uint256 amount) public returns (bool) {
        allowances[msg.sender][delegate] = amount;
        return true;
    }

    function getAllowance(address owner, address delegate)
        public
        view
        returns (uint256)
    {
        // ! don't gorget `view` since no state is modified
        return allowances[owner][delegate];
    }

    // spend as someone else
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount <= balances[from], "Transfer amount exceeds balance.");
        // require(allowances[from][msg.sender] != 0)
        require(
            amount <= allowances[from][msg.sender],
            "Transfer amount exceeds allowance."
        );

        balances[from] -= amount;
        allowances[from][msg.sender] -= amount; // ! don't forget
        balances[to] += amount;
        return true;
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