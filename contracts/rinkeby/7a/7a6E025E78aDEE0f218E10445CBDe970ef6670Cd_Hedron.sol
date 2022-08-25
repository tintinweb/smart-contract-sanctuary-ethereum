// SPDX-License-Identifier: NONE
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Hedron is Ownable {
    // Transfer event declaration
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Approval event declaration
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // a mapping (like a hash table) to store balances
    mapping(address => uint256) private _balances;

    // a mapping to store allowance information
    mapping(address => mapping(address => uint256)) private _allowances;

    // the name of the token
    string private _name = "Hedron";

    // the symbol of the token
    string private _symbol = "HDRN";

    // the total supply of the token
    uint256 private _totalSupply = 0;

    // the number of decimals to use for token divisibility
    uint256 private _decimals = 9;

    // get the ERC20 Token Name
    function name() public view returns (string memory) {
        return _name;
    }

    // get the token Symbol
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // get the number of decimal places
    function decimals() public view returns (uint256) {
        return _decimals;
    }

    // get the total supply of the token that is in the contract
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // get the balance of tokens owned by an address
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // get the allowance that the owner of tokens has assigned to a specific spender
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    // approve allowance for spender to spend certain amount as proxy
    //   requires transaction signing.
    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    // internal _approve utility function for reuse.
    // approves allowance for a spender to spend an approved amount
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        // emit an Approval "event" which will store the event arguments that
        // are passed to the transaction logs
        emit Approval(owner, spender, amount);
    }

    // ERC-20 function to transfer an amount of the token to an address
    function transfer(address to, uint256 amount)
        public
        returns (bool success)
    {
        // owner must be set to the message sender.
        address owner = msg.sender;

        _transfer(owner, to, amount);
        return true;
    }

    // internal utillity function to facilitate the transfer.
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // find out if the message sender's balance is sufficient and require that they have at least that amount
        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        // subtract the amount from the sender's balance.
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        // add the amount to the sender's balance
        _balances[to] += amount;

        // emit the transfer event to transaction logs
        emit Transfer(from, to, amount);
    }

    // function to allow a spender to spend their allowance
    // lets them transfer funds if they have an allowance from the owner of the funds
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // function to check if owner has allowed transfer and then transfer, if allowed for that amount.
    // updates the allowance with the new amount.
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    // Contract Owner Function to allow for the minting of tokens
    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }

    // internal function to handle minting tokens into an account
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        // increase the total supply of the token
        _totalSupply += amount;

        // update the balance of the account address with the minted tokens
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // function to burn tokens from one's supply
    function proofOfBenevolence(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    // function for an an account with an allowance to burn their allowed tokens
    function burnFrom(address account, uint256 amount) public {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    // internal function to choreograph the burn function
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        // emit a transfer event
        emit Transfer(account, address(0), amount);
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