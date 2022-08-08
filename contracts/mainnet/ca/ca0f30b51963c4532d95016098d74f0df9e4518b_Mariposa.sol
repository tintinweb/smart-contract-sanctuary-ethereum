/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)



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


// File contracts/core/Mariposa.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;


/// @title Mariposa
/// @author never

/**
    @notice
    Allowance Contract For the Redacted Ecosystem to mint BTRFLY
*/

interface IBTRFLY {
    function mint(address account_, uint256 amount_) external;
}

contract Mariposa is Pausable, Ownable {
    IBTRFLY public immutable btrflyV2;
    uint256 public immutable supplyCap;

    uint256 public emissions;
    uint256 public totalAllowances;
    mapping(address => uint256) public mintAllowances;
    mapping(address => bool) public isMinter;

    // Push only, beware false-positives. Only for viewing.
    address[] public minters;

    event MintedFor(
        address indexed minter,
        address indexed recipient,
        uint256 amount
    );
    event AddedMinter(address minter);
    event IncreasedAllowance(address indexed minter, uint256 amount);
    event DecreasedAllowance(address indexed minter, uint256 amount);

    error ZeroAddress();
    error ZeroAmount();
    error UnderflowAllowance();
    error ExceedsSupplyCap();
    error NotMinter();
    error AlreadyAdded();

    /**
        @param  _btrflyV2   address  BTRFLYV2 token address
        @param  _supplyCap  uint256  Max number of tokens contract can emit
     */
    constructor(address _btrflyV2, uint256 _supplyCap) {
        if (_btrflyV2 == address(0)) revert ZeroAddress();
        if (_supplyCap == 0) revert ZeroAmount();

        btrflyV2 = IBTRFLY(_btrflyV2);
        supplyCap = _supplyCap;
    }

    /**
        @notice Mints tokens for recipient
        @param  recipient  address  To receive minted tokens
        @param  amount     uint256  Amount
     */
    function mintFor(address recipient, uint256 amount) external whenNotPaused {
        if (!isMinter[msg.sender]) revert NotMinter();
        if (amount == 0) revert ZeroAmount();
        if (recipient == address(0)) revert ZeroAddress();

        mintAllowances[msg.sender] -= amount;
        emissions += amount;
        totalAllowances -= amount;

        emit MintedFor(msg.sender, recipient, amount);

        btrflyV2.mint(recipient, amount);
    }

    /**
        @notice Add address to minter role.
        @param  minter  address  Minter address
     */
    function addMinter(address minter) external onlyOwner {
        if (minter == address(0)) revert ZeroAddress();
        if (isMinter[minter]) revert AlreadyAdded();

        isMinter[minter] = true;
        minters.push(minter);

        emit AddedMinter(minter);
    }

    /**
        @notice Increase allowance
        @param  minter  address  Address with minting rights
        @param  amount  uint256  Amount to increase
     */
    function increaseAllowance(address minter, uint256 amount)
        external
        onlyOwner
    {
        if (!isMinter[minter]) revert NotMinter();
        if (amount == 0) revert ZeroAmount();

        uint256 t = totalAllowances;

        totalAllowances = t + amount;

        if (emissions + totalAllowances > supplyCap) revert ExceedsSupplyCap();

        mintAllowances[minter] += amount;

        emit IncreasedAllowance(minter, amount);
    }

    /**
        @notice Decrease allowance
        @param  minter  address  Address with minting rights
        @param  amount  uint256  Amount to decrease
     */
    function decreaseAllowance(address minter, uint256 amount)
        external
        onlyOwner
    {
        if (!isMinter[minter]) revert NotMinter();
        if (amount == 0) revert ZeroAmount();
        if (mintAllowances[minter] < amount) revert UnderflowAllowance();

        totalAllowances -= amount;
        mintAllowances[minter] -= amount;

        emit DecreasedAllowance(minter, amount);
    }

    /**
        @notice Set the contract's pause state
        @param state  bool  Pause state
    */
    function setPauseState(bool state) external onlyOwner {
        if (state) {
            _pause();
        } else {
            _unpause();
        }
    }
}