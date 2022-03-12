/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

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

contract Payment is Ownable {

    address public spender;
    uint256 public weeklyAllowance;
    uint256 public weekCounter = 1;
    uint256 public totalClaimed;
    uint256 public startTime;
    bool public initialized = false;

    event Initialize(address spender, uint256 weeklyAllowance, uint256 amount);
    event Deposit(address depositor, uint256 amount);
    event Claim(uint256 amountClaimed);
    event Withdrawal(uint256 amountWithdrawed);
    event AllowanceUpdate(uint256 newAllowance);

    function initialize(address _spender, uint256 _weeklyAllowance) public payable onlyOwner {
        require(initialized == false, "already initialized");
        spender = _spender;
        weeklyAllowance = _weeklyAllowance;
        startTime = block.timestamp;
        initialized = true;
        emit Initialize(_spender, _weeklyAllowance, msg.value);
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

    function claim() public {
        require(msg.sender == spender, "Can only be called by spender");
        
        uint256 weeksSinceLastClaim = (block.timestamp - startTime) / 1 seconds;
        uint256 allowance = weeksSinceLastClaim * weeklyAllowance;
        require(getContractBalance() >= allowance, "Gotta top up the balance");
        
        startTime = block.timestamp;
        payable(msg.sender).transfer(allowance);
        totalClaimed += allowance;
        emit Claim(allowance);
    }

    function withdraw(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
        emit Withdrawal(amount);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(msg.sender).transfer(totalBalance);
        emit Withdrawal(totalBalance);
    }

    function editAllowance(uint256 newAllowance) external onlyOwner {
        weeklyAllowance = newAllowance;
        emit AllowanceUpdate(newAllowance);
    }

    function getTotalClaimed() public view returns (uint256) {
        return totalClaimed;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}